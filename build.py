#!/usr/bin/env python3
"""Monta o app a partir de src/.
- index.html: versão do site (GitHub Pages), com manifest, ícones e service worker.
- dist/artifact.html: mesma página sem o cabeçalho, para a prévia no Claude.
Uso: python3 build.py
"""
import os, re, json
R = os.path.dirname(os.path.abspath(__file__))
src = open(f'{R}/src/app.html').read()
logo = 'data:image/png;base64,' + open(f'{R}/src/logo.b64').read().strip()
cfg = json.load(open(f'{R}/src/nuvem.json')) if os.path.exists(f'{R}/src/nuvem.json') else {'url':'','key':''}
page = src.replace('__LOGO__', logo).replace('__SB_URL__', cfg.get('url','')).replace('__SB_KEY__', cfg.get('key',''))
os.makedirs(f'{R}/dist', exist_ok=True)
open(f'{R}/dist/artifact.html','w').write(page)
body = page.replace('<title>Barba &amp; Narga App</title>','',1).replace('<meta name="claude:viewport-fit-sides" content="cover">','',1).replace('<meta name="theme-color" content="#0c0b09">','',1)
head = open(f'{R}/src/head.html').read()
tail = "\n<script>if('serviceWorker' in navigator){ addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(()=>{})); }</script>\n</body>\n</html>\n"
open(f'{R}/index.html','w').write(head + '\n' + body + tail)
js = re.search(r'<script>(.*)</script>', src, re.S).group(1)
open(f'{R}/dist/check.js','w').write(js)
print('ok', len(page))
