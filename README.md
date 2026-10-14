# Barba & Narga · App da casa (protótipo)

App de gestão da Barba & Narga · Club Secreto (barbearia, bar e narga), feito pela Visibility System para apresentação ao cliente.

**Como abrir:** baixe o `index.html` e abra no navegador. É um arquivo só, sem instalação.

## Acessos de demonstração
| Perfil | Usuário | Senha |
|---|---|---|
| Dono (acesso total) | roberto | barba2026 |
| Barbeiro (funcionário) | lucas | equipe2026 |
| Lounge e bar (funcionário) | matheus | equipe2026 |

## O que tem
- Login por pessoa, com tipo **Dono** ou **Funcionário** (permissões em `PERMS`)
- Agenda por barbeiro, com início e conclusão de atendimento, pagamento e consumo do cliente
- Página de agendamento do cliente (serviço → barbeiro → horário livre)
- Estoque separado em Barbearia, Tabacaria e Bar, com entrada, baixa e alertas de mínimo
- Sessão de narga dá baixa automática de essência (15 g), carvão (3 cubos) e piteira (1)
- Separação **Barbearia × Lounge** pelo horário (padrão: sex, sáb e dom das 20h às 3h); venda no lounge bloqueada fora dos dias de lounge
- Noites de lounge: tudo o que foi vendido em cada noite, pagamentos, quem lançou, saída de estoque e lucro estimado
- Relatórios, equipe e acessos, serviços e preços (só dono)

## Limitações do protótipo
- Os dados ficam no navegador de quem abre (`localStorage`) e voltam ao exemplo a cada dia.
- Nomes, preços e quantidades são exemplos.
- Para uso real, com todos os celulares vendo a mesma agenda e o mesmo estoque, falta um banco de dados.

Estrutura do código igual à do app da Chiq Cell: `DB` (dados) → `PERMS` (papéis) → `ROUTES` (telas).
