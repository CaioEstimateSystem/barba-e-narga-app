# Barba & Narga · App da casa

App de gestão da Barba & Narga · Club Secreto (barbearia, bar e narga), feito pela Visibility System para apresentação ao cliente.

**Endereço:** https://caioestimatesystem.github.io/barba-e-narga-app/ (dá para adicionar à tela de início do celular).

O app tem dois modos:
- **Demonstração:** quem abre o endereço sem estar conectado vê dados de exemplo, que ficam só naquele aparelho.
- **Oficial:** o celular aberto pelo link de conexão (`#conectar=<código da casa>`) usa o banco compartilhado. Todos os celulares conectados veem a mesma agenda, pedidos, vendas e estoque, com atualização a cada poucos segundos e fila offline.

## Acessos de demonstração (só no modo demonstração)
| Perfil | Usuário | Senha |
|---|---|---|
| Dono (acesso total) | roberto | barba2026 |
| Barbeiro (funcionário) | lucas | equipe2026 |
| Lounge e bar (funcionário) | matheus | equipe2026 |

## O que tem (6 telas)
- **Resultados** (só dono): quanto entrou hoje, em 7 ou 30 dias, separado entre barbearia (serviços + consumo) e lounge; barbeiros e comissões; cada noite de lounge com tudo o que foi vendido.
- **Agenda:** horários por barbeiro. Ao concluir, o barbeiro cobra o serviço e o que o cliente consumiu num pagamento só.
- **Pedidos:** toda venda vira um pedido para o bar: Novo → Preparando (quem pegou) → Pronto → Entregue. Quem recebe os pedidos é marcado em Ajustes. O barbeiro pode pedir bebida para a cadeira durante o corte; cobra no fim.
- **Vendas:** o caixa. Um jeito só de vender bebida, narga ou produto. O período (barbearia ou lounge) é definido pelo horário.
- **Estoque:** uma tela com os três setores. Vendas dão baixa sozinhas; cada narga desconta essência, carvão e piteira.
- **Ajustes** (só dono): equipe e acessos, serviços e preços, horário de funcionamento, lounge, narga, link de agendamento do cliente e link de conexão dos celulares.

Funcionário vê Agenda, Pedidos, Vendas e Estoque.

## Colocar no ar (modo oficial)
1. Criar um projeto no Supabase (região São Paulo).
2. No SQL Editor, rodar `supabase/setup.sql` trocando `__SEGREDO__` por um código aleatório longo. **O código não vai para o repositório.**
3. Criar `src/nuvem.json` com `{"url": "<URL do projeto>", "key": "<chave publishable/anon>"}` e rodar `python3 build.py`.
4. Publicar e abrir `…/#conectar=<código>` no celular do dono. No primeiro acesso ele cria o próprio usuário e a casa começa vazia, com o catálogo padrão para ajustar.
5. A lista "Deixar a casa pronta" em Resultados guia o resto: equipe, preços, contagem do estoque, conectar os celulares, link na bio.

Link do cliente: `…/#agendar`.

## Segurança
- Senhas guardadas como hash (SHA-256 com o usuário), nunca em texto.
- O banco não aceita acesso direto às tabelas; tudo passa por funções que conferem o código da casa.
- O cliente só vê horários ocupados (sem nomes) e só consegue marcar horário válido e livre.

Estrutura do código igual à do app da Chiq Cell: `DB` (dados) → `PERMS` (papéis) → `ROUTES` (telas).
