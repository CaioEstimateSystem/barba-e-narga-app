#!/usr/bin/env python3
"""Imita a API do Supabase (só /rest/v1/rpc) usando um Postgres local, para testar o app sem internet.
Uso: python3 supabase/servidor_teste.py <porta> <socket_dir> <pg_port>"""
import sys, json, subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
PORT, SOCK, PGPORT = int(sys.argv[1]), sys.argv[2], sys.argv[3]
ARGS = {'sync_puxar':['p_casa','p_segredo','p_desde','p_folga'], 'sync_enviar':['p_casa','p_segredo','p_linhas'], 'agenda_publica':['p_casa'], 'agendar':['p_casa','p_reserva']}
TIPOS = {'p_linhas':'jsonb','p_reserva':'jsonb','p_folga':'boolean'}
def lit(v): return 'null' if v is None else "'" + (json.dumps(v) if isinstance(v,(dict,list)) else str(v).lower() if isinstance(v,bool) else str(v)).replace("'","''") + "'"
class H(BaseHTTPRequestHandler):
    def log_message(self,*a): pass
    def cors(self):
        self.send_header('Access-Control-Allow-Origin','*'); self.send_header('Access-Control-Allow-Headers','*'); self.send_header('Access-Control-Allow-Methods','POST, OPTIONS')
    def do_OPTIONS(self): self.send_response(204); self.cors(); self.end_headers()
    def do_POST(self):
        fn = self.path.rsplit('/',1)[-1]
        body = json.loads(self.rfile.read(int(self.headers.get('Content-Length',0))) or b'{}')
        if fn not in ARGS: self.send_response(404); self.cors(); self.end_headers(); return
        a = ', '.join(f"{k} => {lit(body.get(k))}::{TIPOS.get(k,'text')}" for k in ARGS[fn] if k in body)
        sel = f"select coalesce(json_agg(t),'[]') from public.{fn}({a}) t" if fn=='sync_puxar' else f"select to_json(public.{fn}({a}))"
        r = subprocess.run(['psql','-h',SOCK,'-p',PGPORT,'-U','postgres','-tAq','-v','ON_ERROR_STOP=1','-c',f"set role anon; {sel}"], capture_output=True, text=True)
        if r.returncode:
            msg = r.stderr.split('ERROR:')[-1].split('\n')[0].strip()
            code = '28000' if 'segredo' in msg else 'P0001'
            out = json.dumps({'message':msg,'code':code}).encode(); self.send_response(400)
        else:
            out = r.stdout.strip().encode() or b'null'; self.send_response(200)
        self.cors(); self.send_header('Content-Type','application/json'); self.end_headers(); self.wfile.write(out)
ThreadingHTTPServer(('127.0.0.1',PORT),H).serve_forever()
