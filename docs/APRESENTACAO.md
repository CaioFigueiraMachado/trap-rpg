# Roteiro da apresentação — Trap RPG

Dupla: **Caio Machado e Lucas Henrique** · Tempo sugerido: 8 a 10 minutos.

---

## Antes de começar (checklist)

- [ ] No Supabase: **Authentication → Sign In / Providers → Email → Confirm email** desligado.
- [ ] App aberto (`flutter run -d chrome` ou no celular) e **deslogado**.
- [ ] Um e-mail novo para cadastrar ao vivo (ex.: `demo1@teste.com`).
- [ ] Painel do Supabase aberto em **Table Editor** para mostrar os dados salvos.
- [ ] (Opcional) Músicas em `lib/assets/music/` para tocar na coleção/batalha.

---

## Parte 1 — Demonstração (cenário exigido no item 5 do PDF)

| # | O que fazer | O que falar |
|---|---|---|
| 1 | **Cadastro**: Splash → "Cadastre-se" → apelido, e-mail, senha → CADASTRAR | "O cadastro usa o Supabase Auth. Um trigger no banco cria o perfil e entrega 3 cartas iniciais." |
| 2 | **Home**: mostrar saudação, pontos, nível, missão em destaque, filtros (status, categoria, dificuldade) | "As missões vêm da tabela `missions` e o status de cada uma vem da `user_missions` do usuário logado." |
| 3 | Abrir **Primeiro Freestyle** → **Iniciar missão** → **Ir para a batalha** → escolher 3 cartas → vencer | "O id da missão vai pela rota `/mission/:id` e o objeto pelo `extra` do GoRouter. Ao vencer, chamamos a função `complete_mission` no banco." |
| 4 | Mostrar **+50 pontos**, carta da Stef recrutada e conquista "Primeira Rima"; voltar à Home e ver pontos/nível atualizados | "Os pontos são somados no servidor, só uma vez. Se eu jogar a revanche, ele não pontua de novo." (mostrar a revanche) |
| 5 | Abrir **Conquistas** (desbloqueada x bloqueadas com progresso) e **Ranking** (pódio + "Sua posição") | "O ranking é calculado no banco pela função `get_ranking`, a partir dos pontos salvos, não de uma lista fixa." |
| 6 | **Perfil** → SAIR → entrar de novo com o mesmo e-mail → mostrar que tudo continua; abrir o **Table Editor** do Supabase (`profiles`, `user_missions`) | "Os dados estão no PostgreSQL, ligados ao `user_id` do usuário autenticado." |

Extra (se sobrar tempo): **Cartas** → tocar numa carta (arte completa + música) e redimensionar a janela
do navegador para mostrar o layout responsivo (barra inferior ↔ menu lateral).

---

## Parte 2 — Explicação técnica (o professor vai perguntar)

### Como organizamos os widgets
- Pasta `lib/widgets/` com componentes **reutilizáveis que recebem dados por parâmetro**:
  - `MissionCard` (`mission_card.dart`) — cartão da missão, usado na Home (lista e destaque).
  - `ProgressCard` (`progress_card.dart`) — pontos, nível e progresso.
  - `AchievementBadge` (`achievement_badge.dart`) — conquista bloqueada/desbloqueada (tela de conquistas e tela de vitória).
  - `TrapperCardWidget` e `TrapperAvatar` — a carta e o avatar, usados na coleção, missão, batalha e recompensa.
  - `FutureView`, `LoadingView`, `EmptyView`, `ErrorView` (`state_views.dart`) — carregando, lista vazia e erro em todas as telas.
- Telas em `lib/screens/`, regras da batalha em `lib/game/battle_engine.dart` (Dart puro, testável),
  acesso ao banco centralizado em `lib/services/game_repository.dart`.

### Como implementamos as rotas (GoRouter) — `lib/core/router.dart`
- Rotas: `/` (splash), `/login`, `/register`, abas `/home`, `/collection`, `/achievements`, `/ranking`, `/profile`,
  e `/mission/:id` → `/mission/:id/battle`.
- **Passagem de parâmetro**: o `id` vai na URL (`state.pathParameters['id']`) e o objeto `Mission` no `extra`.
  Se o `extra` se perder (ex.: recarregar a página na web), a tela busca a missão pelo id.
- **Proteção**: o `redirect` verifica `auth.currentSession`; sem sessão, qualquer rota interna vai para `/login`.
  O `refreshListenable` escuta o `onAuthStateChange` do Supabase, então login/logout redirecionam sozinhos.
- **Abas**: `StatefulShellRoute.indexedStack` mantém o estado de cada aba (barra inferior no celular,
  menu lateral no computador).

### Como relacionamos os dados do usuário com as missões concluídas
- `profiles.id` = `auth.users.id` (1 para 1).
- `user_missions (user_id, mission_id, status, completed_at, points_awarded)` com **chave primária
  `(user_id, mission_id)`** → uma linha por missão por jogador; impossível duplicar.
- O app **não tem permissão de INSERT/UPDATE** nessas tabelas. Ele chama funções no banco
  (`start_mission`, `complete_mission`) que usam `auth.uid()` para saber quem é o jogador.
- `complete_mission`: grava a conclusão só se ainda não estava concluída, soma os pontos em `profiles`,
  entrega a carta de recompensa (`user_cards`) e verifica as conquistas (`user_achievements`).
- **RLS**: cada jogador só lê os próprios registros; no perfil só pode alterar o próprio apelido
  (a coluna `points` é protegida). Assim a pontuação não pode ser manipulada pelo app.

---

## Perguntas prováveis

- **"E se alguém tentar mandar pontos direto pela API?"** — O papel `authenticated` não tem permissão
  de UPDATE na coluna `points` nem INSERT em `user_missions`. Testamos: o banco responde *permission denied*.
- **"A conclusão é real?"** — A conclusão é a vitória numa batalha de cartas (o PDF permite simular);
  o registro e a pontuação são reais, no banco.
- **"Onde estão os dados das cartas/missões?"** — Nas tabelas `cards`, `missions` e `achievements`
  (script completo em `supabase/schema.sql`).
- **"Por que a chave do Supabase está no código?"** — É a chave pública (publishable/anon), feita para o
  cliente. A segurança está no RLS e nas funções do servidor.

## Divisão sugerida da fala
- **Caio**: demonstração (Parte 1, passos 1 a 3) + widgets.
- **Lucas Henrique**: demonstração (passos 4 a 6) + rotas e banco de dados.
