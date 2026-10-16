-- Barba & Narga · banco de dados do app (Supabase / Postgres)
-- Rodar uma vez no SQL Editor do projeto. Pode rodar de novo: não apaga dados.
-- O código da casa (__SEGREDO__) é trocado na hora de rodar e NUNCA vai para o repositório.

create table if not exists public.casas (
  id text primary key,
  segredo text not null,
  criado_em timestamptz not null default now()
);

create table if not exists public.registros (
  casa text not null references public.casas(id) on delete cascade,
  col text not null check (col in ('users','services','produtos','bookings','vendas','movs','cfg')),
  id text not null,
  data jsonb not null default '{}'::jsonb,
  deleted boolean not null default false,
  criado_em timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  primary key (casa, col, id)
);
create index if not exists registros_casa_updated on public.registros (casa, updated_at);

-- Ninguém acessa as tabelas direto: só pelas funções abaixo
alter table public.casas enable row level security;
alter table public.registros enable row level security;
revoke all on public.casas from anon, authenticated;
revoke all on public.registros from anon, authenticated;

create or replace function public._confere(p_casa text, p_segredo text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_segredo is null or not exists (select 1 from casas where id = p_casa and segredo = p_segredo) then
    raise exception 'segredo invalido' using errcode = '28000';
  end if;
end $$;

-- Baixa o que mudou desde o último horário visto (o app passa o último updated_at que recebeu)
create or replace function public.sync_puxar(p_casa text, p_segredo text, p_desde text, p_folga boolean default true)
returns table(col text, id text, data jsonb, deleted boolean, updated_at text)
language plpgsql security definer set search_path = public as $$
begin
  perform _confere(p_casa, p_segredo);
  return query
    select r.col, r.id, r.data, r.deleted,
           to_char(r.updated_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
    from registros r
    where r.casa = p_casa
      and r.updated_at > (p_desde::timestamptz - case when p_folga then interval '3 seconds' else interval '0' end)
    order by r.updated_at asc
    limit 1000;
end $$;

-- Grava um lote de registros (cria, altera ou marca como apagado)
create or replace function public.sync_enviar(p_casa text, p_segredo text, p_linhas jsonb) returns integer
language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  perform _confere(p_casa, p_segredo);
  insert into registros (casa, col, id, data, deleted)
  select p_casa, l->>'col', l->>'id', coalesce(l->'data', '{}'::jsonb), coalesce((l->>'deleted')::boolean, false)
  from jsonb_array_elements(p_linhas) l
  where l->>'col' in ('users','services','produtos','bookings','vendas','movs','cfg') and coalesce(l->>'id','') <> ''
  on conflict (casa, col, id) do update
    set data = excluded.data, deleted = excluded.deleted, updated_at = clock_timestamp();
  get diagnostics n = row_count;
  return n;
end $$;

-- Página pública de agendamento: só serviços, barbeiros e horários ocupados (sem nome nem telefone de cliente)
create or replace function public.agenda_publica(p_casa text) returns jsonb
language sql security definer set search_path = public as $$
  select jsonb_build_object(
    'services', (select coalesce(jsonb_agg(jsonb_build_object('id', r.id, 'nome', r.data->>'nome', 'preco', (r.data->>'preco')::numeric, 'dur', (r.data->>'dur')::int) order by r.criado_em), '[]'::jsonb)
                 from registros r where r.casa = p_casa and r.col = 'services' and not r.deleted),
    'barbeiros', (select coalesce(jsonb_agg(jsonb_build_object('id', r.id, 'nome', r.data->>'nome') order by r.criado_em), '[]'::jsonb)
                 from registros r where r.casa = p_casa and r.col = 'users' and not r.deleted
                   and coalesce((r.data->>'ativo')::boolean, true)
                   and coalesce((r.data->>'barbeiro')::boolean, (r.data->>'funcao') ilike '%barbeir%')),
    'ocupados', (select coalesce(jsonb_agg(jsonb_build_object('date', b.data->>'date', 'time', b.data->>'time', 'barber', b.data->>'barber', 'dur', coalesce((s.data->>'dur')::int, 30))), '[]'::jsonb)
                 from registros b
                 left join registros s on s.casa = b.casa and s.col = 'services' and s.id = b.data->>'service'
                 where b.casa = p_casa and b.col = 'bookings' and not b.deleted
                   and coalesce(b.data->>'status','') <> 'cancelado'
                   and (b.data->>'date') >= to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM-DD')),
    'horario', (select r.data->'horario' from registros r where r.casa = p_casa and r.col = 'cfg' and r.id = 'main' and not r.deleted),
    'agora', to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM-DD"T"HH24:MI')
  );
$$;

-- Cliente marca um horário. Confere serviço, barbeiro, dia aberto, horário dentro do expediente e conflito.
create or replace function public.agendar(p_casa text, p_reserva jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_id text := p_reserva->>'id';
  v_date text := p_reserva->>'date';
  v_time text := p_reserva->>'time';
  v_barber text := p_reserva->>'barber';
  v_service text := p_reserva->>'service';
  v_cli text := trim(coalesce(p_reserva->>'cliente', ''));
  v_tel text := trim(coalesce(p_reserva->>'tel', ''));
  v_hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  v_agora int := extract(hour from now() at time zone 'America/Sao_Paulo')::int*60 + extract(minute from now() at time zone 'America/Sao_Paulo')::int;
  v_dur int; v_preco numeric; v_ini int; v_conf int; v_h jsonb; v_abre int := 540; v_fecha int := 1260;
begin
  if v_id is null or v_id !~ '^[a-z0-9]{6,24}$' then raise exception 'reserva invalida'; end if;
  if v_cli = '' or length(v_cli) > 80 or length(regexp_replace(v_tel, '\D', '', 'g')) < 10 or length(v_tel) > 30 then raise exception 'dados invalidos'; end if;
  if v_date !~ '^\d{4}-\d{2}-\d{2}$' or v_time !~ '^\d{2}:\d{2}$' then raise exception 'data invalida'; end if;
  if v_date::date < v_hoje or v_date::date > v_hoje + 14 then raise exception 'data fora do periodo'; end if;
  select (data->>'dur')::int, (data->>'preco')::numeric into v_dur, v_preco
    from registros where casa = p_casa and col = 'services' and id = v_service and not deleted;
  if v_dur is null then raise exception 'servico invalido'; end if;
  if not exists (select 1 from registros where casa = p_casa and col = 'users' and id = v_barber and not deleted
                 and coalesce((data->>'ativo')::boolean, true)
                 and coalesce((data->>'barbeiro')::boolean, (data->>'funcao') ilike '%barbeir%')) then raise exception 'barbeiro invalido'; end if;
  select data->'horario' into v_h from registros where casa = p_casa and col = 'cfg' and id = 'main' and not deleted;
  if v_h is not null then
    if v_h ? 'abre' then v_abre := split_part(v_h->>'abre', ':', 1)::int*60 + split_part(v_h->>'abre', ':', 2)::int; end if;
    if v_h ? 'fecha' then v_fecha := split_part(v_h->>'fecha', ':', 1)::int*60 + split_part(v_h->>'fecha', ':', 2)::int; end if;
    if (v_h->'fechado') @> to_jsonb(extract(dow from v_date::date)::int) then raise exception 'dia fechado'; end if;
  end if;
  v_ini := split_part(v_time, ':', 1)::int*60 + split_part(v_time, ':', 2)::int;
  if v_ini < v_abre or v_ini + v_dur > v_fecha then raise exception 'fora do horario'; end if;
  if v_date::date = v_hoje and v_ini < v_agora then raise exception 'horario passou'; end if;
  perform pg_advisory_xact_lock(hashtext(p_casa || v_date || v_barber));
  select count(*) into v_conf
    from registros b
    left join registros s on s.casa = b.casa and s.col = 'services' and s.id = b.data->>'service'
    where b.casa = p_casa and b.col = 'bookings' and not b.deleted
      and b.data->>'date' = v_date and b.data->>'barber' = v_barber and coalesce(b.data->>'status','') <> 'cancelado'
      and v_ini < (split_part(b.data->>'time', ':', 1)::int*60 + split_part(b.data->>'time', ':', 2)::int) + coalesce((s.data->>'dur')::int, 30)
      and v_ini + v_dur > (split_part(b.data->>'time', ':', 1)::int*60 + split_part(b.data->>'time', ':', 2)::int);
  if v_conf > 0 then raise exception 'horario ocupado'; end if;
  insert into registros (casa, col, id, data) values (p_casa, 'bookings', v_id, jsonb_build_object(
    'id', v_id, 'date', v_date, 'time', v_time, 'barber', v_barber, 'cliente', v_cli, 'tel', v_tel,
    'service', v_service, 'valor', v_preco, 'status', 'agendado', 'origem', 'cliente', 'pay', null));
  return jsonb_build_object('ok', true, 'id', v_id, 'valor', v_preco);
end $$;

revoke execute on function public._confere(text, text) from public, anon, authenticated;
grant execute on function public.sync_puxar(text, text, text, boolean) to anon;
grant execute on function public.sync_enviar(text, text, jsonb) to anon;
grant execute on function public.agenda_publica(text) to anon;
grant execute on function public.agendar(text, jsonb) to anon;

insert into public.casas (id, segredo) values ('barbaenarga', '__SEGREDO__') on conflict (id) do nothing;
