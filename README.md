# Barba & Narga · App da casa (protótipo)

App de gestão da Barba & Narga · Club Secreto (barbearia, bar e narga), feito pela Visibility System para apresentação ao cliente.

**Como abrir:** baixe o `index.html` e abra no navegador. É um arquivo só, sem instalação.

## Acessos de demonstração
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
- **Ajustes** (só dono): equipe e acessos, serviços e preços, horário do lounge, página de agendamento do cliente.

Funcionário vê Agenda, Pedidos, Vendas e Estoque.

## Limitações do protótipo
- Os dados ficam no navegador de quem abre (`localStorage`) e voltam ao exemplo a cada dia.
- Nomes, preços e quantidades são exemplos.
- Para uso real, com todos os celulares vendo a mesma agenda e o mesmo estoque, falta um banco de dados.

Estrutura do código igual à do app da Chiq Cell: `DB` (dados) → `PERMS` (papéis) → `ROUTES` (telas).
