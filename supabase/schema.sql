-- =====================================================================
--  TRAP RPG — Duelo de Cartas
--  Esquema completo do banco de dados (Supabase / PostgreSQL)
--
--  Como usar: Supabase Dashboard > SQL Editor > cole este arquivo > Run.
--  O script pode ser executado mais de uma vez (é idempotente).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. TABELAS
-- ---------------------------------------------------------------------

-- Perfil do jogador (1:1 com auth.users). A pontuação só é alterada
-- pelas funções do servidor, nunca diretamente pelo app.
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  nickname    text not null check (char_length(nickname) between 2 and 20),
  points      integer not null default 0 check (points >= 0),
  created_at  timestamptz not null default now()
);

-- Cartas (os trappers) com atributos de RPG.
create table if not exists public.cards (
  id             text primary key,
  name           text not null,
  title          text not null,
  element        text not null check (element in ('fogo','gelo','vento','terra','tempestade','sombra','luz','cosmico')),
  rarity         text not null check (rarity in ('comum','rara','epica','lendaria')),
  attack         integer not null check (attack > 0),
  defense        integer not null check (defense >= 0),
  hp             integer not null check (hp > 0),
  special_name   text not null,
  special_type   text not null check (special_type in ('damage','pierce','aoe','drain','stun','heal')),
  special_power  integer not null check (special_power > 0),
  special_desc   text not null,
  lore           text not null default '',
  is_starter     boolean not null default false,
  sort_order     integer not null default 0
);

-- Missões (batalhas). Cada uma tem um time inimigo e pode dar uma carta.
create table if not exists public.missions (
  id              integer primary key,
  title           text not null,
  description     text not null,
  guidance        text not null,
  category        text not null check (category in ('treino','batalha','torneio','chefe')),
  difficulty      text not null check (difficulty in ('facil','medio','dificil','lendario')),
  points          integer not null check (points > 0),
  enemy_cards     text[] not null,
  enemy_level     integer not null default 1 check (enemy_level between 1 and 10),
  reward_card_id  text references public.cards (id),
  is_featured     boolean not null default false,
  sort_order      integer not null default 0
);

-- Missões iniciadas/concluídas por usuário. A PK composta impede que a
-- mesma missão seja registrada (e pontuada) duas vezes para o mesmo jogador.
create table if not exists public.user_missions (
  user_id         uuid not null references auth.users (id) on delete cascade,
  mission_id      integer not null references public.missions (id) on delete cascade,
  status          text not null check (status in ('in_progress','completed')),
  started_at      timestamptz not null default now(),
  completed_at    timestamptz,
  points_awarded  integer not null default 0,
  primary key (user_id, mission_id)
);

-- Conquistas disponíveis. condition_type define a regra de desbloqueio.
create table if not exists public.achievements (
  id                  text primary key,
  name                text not null,
  description         text not null,
  icon                text not null,
  condition_type      text not null check (condition_type in ('missions_completed','distinct_days','category_completed','points','cards_owned')),
  condition_value     integer not null check (condition_value > 0),
  condition_category  text,
  sort_order          integer not null default 0
);

create table if not exists public.user_achievements (
  user_id         uuid not null references auth.users (id) on delete cascade,
  achievement_id  text not null references public.achievements (id) on delete cascade,
  unlocked_at     timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

-- Coleção de cartas de cada jogador.
create table if not exists public.user_cards (
  user_id      uuid not null references auth.users (id) on delete cascade,
  card_id      text not null references public.cards (id) on delete cascade,
  obtained_at  timestamptz not null default now(),
  primary key (user_id, card_id)
);

create index if not exists user_missions_mission_idx      on public.user_missions (mission_id);
create index if not exists user_achievements_ach_idx      on public.user_achievements (achievement_id);
create index if not exists user_cards_card_idx            on public.user_cards (card_id);
create index if not exists missions_reward_card_idx       on public.missions (reward_card_id);
create index if not exists profiles_points_idx            on public.profiles (points desc);


-- ---------------------------------------------------------------------
-- 2. SEGURANÇA (RLS + permissões)
-- ---------------------------------------------------------------------

alter table public.profiles           enable row level security;
alter table public.cards              enable row level security;
alter table public.missions           enable row level security;
alter table public.user_missions      enable row level security;
alter table public.achievements       enable row level security;
alter table public.user_achievements  enable row level security;
alter table public.user_cards         enable row level security;

-- O app (anon/authenticated) não escreve diretamente em nenhuma tabela,
-- exceto o apelido do próprio perfil. Todo o resto passa pelas funções.
revoke insert, update, delete on
  public.profiles, public.cards, public.missions, public.user_missions,
  public.achievements, public.user_achievements, public.user_cards
from anon, authenticated;

grant select on
  public.profiles, public.cards, public.missions, public.user_missions,
  public.achievements, public.user_achievements, public.user_cards
to authenticated;

-- Só a coluna nickname pode ser atualizada pelo cliente (points NÃO).
grant update (nickname) on public.profiles to authenticated;

-- profiles: todos os logados veem apelido/pontos (ranking); cada um só edita o seu.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated using (true);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Catálogos públicos para usuários logados.
drop policy if exists cards_select on public.cards;
create policy cards_select on public.cards for select to authenticated using (true);

drop policy if exists missions_select on public.missions;
create policy missions_select on public.missions for select to authenticated using (true);

drop policy if exists achievements_select on public.achievements;
create policy achievements_select on public.achievements for select to authenticated using (true);

-- Dados privados: cada jogador só enxerga os próprios registros.
drop policy if exists user_missions_select_own on public.user_missions;
create policy user_missions_select_own on public.user_missions
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists user_achievements_select_own on public.user_achievements;
create policy user_achievements_select_own on public.user_achievements
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists user_cards_select_own on public.user_cards;
create policy user_cards_select_own on public.user_cards
  for select to authenticated using ((select auth.uid()) = user_id);


-- ---------------------------------------------------------------------
-- 3. FUNÇÕES DO JOGO (executam no servidor, com regras de negócio)
-- ---------------------------------------------------------------------

-- Cria o perfil e entrega as cartas iniciais quando alguém se cadastra.
create or replace function public.handle_new_trap_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_nick text := left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'nickname'), ''),
                               split_part(new.email, '@', 1)), 20);
begin
  if char_length(v_nick) < 2 then
    v_nick := 'MC ' || v_nick;
  end if;

  insert into public.profiles (id, nickname) values (new.id, v_nick)
  on conflict (id) do nothing;

  insert into public.user_cards (user_id, card_id)
  select new.id, c.id from public.cards c where c.is_starter
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_trap on auth.users;
create trigger on_auth_user_created_trap
  after insert on auth.users
  for each row execute function public.handle_new_trap_user();


-- Verifica e desbloqueia conquistas. Retorna as conquistas NOVAS (json).
create or replace function public.check_achievements(p_user_id uuid)
returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_completed integer;
  v_days      integer;
  v_points    integer;
  v_cards     integer;
  v_result    json;
begin
  select count(*),
         count(distinct (um.completed_at at time zone 'America/Sao_Paulo')::date)
    into v_completed, v_days
    from public.user_missions um
   where um.user_id = p_user_id and um.status = 'completed';

  select p.points into v_points from public.profiles p where p.id = p_user_id;
  select count(*) into v_cards from public.user_cards uc where uc.user_id = p_user_id;

  with eligible as (
    select a.id
      from public.achievements a
     where case a.condition_type
             when 'missions_completed' then v_completed >= a.condition_value
             when 'distinct_days'      then v_days      >= a.condition_value
             when 'points'             then v_points    >= a.condition_value
             when 'cards_owned'        then v_cards     >= a.condition_value
             when 'category_completed' then (
               select count(*)
                 from public.user_missions um
                 join public.missions m on m.id = um.mission_id
                where um.user_id = p_user_id
                  and um.status = 'completed'
                  and m.category = a.condition_category
             ) >= a.condition_value
             else false
           end
  ),
  inserted as (
    insert into public.user_achievements (user_id, achievement_id)
    select p_user_id, e.id from eligible e
    on conflict do nothing
    returning achievement_id
  )
  select coalesce(
           json_agg(json_build_object('id', a.id, 'name', a.name,
                                      'description', a.description, 'icon', a.icon)
                    order by a.sort_order),
           '[]'::json)
    into v_result
    from inserted i
    join public.achievements a on a.id = i.achievement_id;

  return v_result;
end;
$$;


-- Inicia uma missão para o usuário logado. Retorna o status atual.
create or replace function public.start_mission(p_mission_id integer)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid();
  v_status text;
begin
  if v_uid is null then
    raise exception 'Usuário não autenticado';
  end if;
  if not exists (select 1 from public.missions where id = p_mission_id) then
    raise exception 'Missão não encontrada';
  end if;

  insert into public.user_missions (user_id, mission_id, status)
  values (v_uid, p_mission_id, 'in_progress')
  on conflict (user_id, mission_id) do nothing;

  select status into v_status
    from public.user_missions
   where user_id = v_uid and mission_id = p_mission_id;

  return v_status;
end;
$$;


-- Conclui uma missão: registra, soma os pontos (uma única vez),
-- entrega a carta de recompensa e verifica conquistas.
create or replace function public.complete_mission(p_mission_id integer)
returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid();
  v_points    integer;
  v_reward    text;
  v_new_card  boolean := false;
  v_new_ach   json;
begin
  if v_uid is null then
    raise exception 'Usuário não autenticado';
  end if;

  select m.points, m.reward_card_id into v_points, v_reward
    from public.missions m where m.id = p_mission_id;
  if not found then
    raise exception 'Missão não encontrada';
  end if;

  -- Só grava se ainda não estiver concluída (o WHERE impede pontuar 2x,
  -- inclusive em requisições simultâneas).
  insert into public.user_missions (user_id, mission_id, status, completed_at, points_awarded)
  values (v_uid, p_mission_id, 'completed', now(), v_points)
  on conflict (user_id, mission_id) do update
     set status = 'completed',
         completed_at = excluded.completed_at,
         points_awarded = excluded.points_awarded
   where public.user_missions.status <> 'completed';

  if not found then
    return json_build_object('already_completed', true, 'points_awarded', 0,
                             'new_achievements', '[]'::json, 'reward_card', null);
  end if;

  update public.profiles set points = points + v_points where id = v_uid;

  if v_reward is not null then
    insert into public.user_cards (user_id, card_id) values (v_uid, v_reward)
    on conflict do nothing;
    v_new_card := found;
  end if;

  v_new_ach := public.check_achievements(v_uid);

  return json_build_object(
    'already_completed', false,
    'points_awarded',    v_points,
    'new_achievements',  v_new_ach,
    'reward_card',       case when v_new_card then v_reward end
  );
end;
$$;


-- Ranking calculado a partir dos dados persistidos. Retorna o top N
-- e, se o usuário logado estiver fora dele, também a linha dele.
create or replace function public.get_ranking(p_limit integer default 50)
returns table (
  rank_position       bigint,
  player_id           uuid,
  nickname            text,
  points              integer,
  missions_completed  bigint,
  is_me               boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with ranked as (
    select row_number() over (order by p.points desc, p.created_at asc) as rank_position,
           p.id as player_id,
           p.nickname,
           p.points,
           (select count(*) from public.user_missions um
             where um.user_id = p.id and um.status = 'completed') as missions_completed,
           p.id = auth.uid() as is_me
      from public.profiles p
  )
  select r.rank_position, r.player_id, r.nickname, r.points, r.missions_completed, r.is_me
    from ranked r
   where r.rank_position <= p_limit or r.is_me
   order by r.rank_position;
$$;

-- Permissões das funções: só usuários logados chamam as RPCs do jogo.
revoke all on function public.handle_new_trap_user()        from public, anon, authenticated;
revoke all on function public.check_achievements(uuid)      from public, anon, authenticated;
revoke all on function public.start_mission(integer)        from public, anon;
revoke all on function public.complete_mission(integer)     from public, anon;
revoke all on function public.get_ranking(integer)          from public, anon;
grant execute on function public.start_mission(integer)     to authenticated;
grant execute on function public.complete_mission(integer)  to authenticated;
grant execute on function public.get_ranking(integer)       to authenticated;


-- ---------------------------------------------------------------------
-- 4. DADOS INICIAIS (cartas, missões e conquistas)
-- ---------------------------------------------------------------------

insert into public.cards
  (id, name, title, element, rarity, attack, defense, hp, special_name, special_type, special_power, special_desc, lore, is_starter, sort_order)
values
  ('fabin', 'Fabin', 'Escudeiro do Corre', 'terra', 'comum', 18, 12, 100,
   'Corre Sem Parar', 'heal', 20, 'Cura 20% da vida máxima de todo o time.',
   'Nunca para de correr atrás. Segura a linha de frente enquanto o time se recupera.', true, 1),
  ('leviano', 'Leviano', 'Andarilho dos Ventos', 'vento', 'rara', 22, 9, 95,
   'Rajada Leve', 'stun', 110, 'Causa 110% de dano e atordoa o alvo por 1 turno.',
   'Leve como o vento, aparece e some no meio da batalha deixando o rival tonto.', true, 2),
  ('reid', 'Reid', 'Arqueiro Sônico', 'luz', 'rara', 23, 10, 95,
   'Flecha Sônica', 'pierce', 150, 'Dispara uma flecha de som que causa 150% de dano e ignora a defesa.',
   'Mira certeira: cada verso é uma flecha que atravessa qualquer armadura.', true, 3),
  ('stef', 'Stef', 'Feiticeira do Auto-Tune', 'gelo', 'rara', 21, 11, 100,
   'Nevasca Afinada', 'aoe', 80, 'Congela o palco: 80% de dano em todos os inimigos.',
   'Com a voz afinada no gelo, transforma qualquer arena em uma nevasca.', false, 4),
  ('klisman', 'Klisman', 'Guardião do Grave', 'terra', 'rara', 19, 16, 125,
   'Muralha do Grave', 'heal', 30, 'Ergue uma muralha de grave que cura 30% da vida de todo o time.',
   'O grave dele é tão pesado que vira escudo. O tanque oficial de qualquer line-up.', false, 5),
  ('alee', 'Alee', 'Duelista Noturno', 'sombra', 'epica', 28, 12, 105,
   'Lâmina Noturna', 'drain', 160, 'Golpe sombrio de 160% de dano que rouba metade do dano como vida.',
   'Ataca nas sombras da madrugada e sai da batalha mais forte do que entrou.', false, 6),
  ('phlnoturnboy', 'Phlnoturnboy', 'Bruxo da Madrugada', 'sombra', 'epica', 26, 11, 110,
   'Eclipse da Madrugada', 'stun', 140, 'Invoca um eclipse: 140% de dano e atordoa o alvo.',
   'Só aparece depois da meia-noite. Quando o eclipse começa, ninguém se mexe.', false, 7),
  ('fabgodamn', 'FabGoDamn', 'Berserker do Beat', 'fogo', 'epica', 31, 9, 108,
   'Fúria do 808', 'damage', 220, 'Explode o 808 e causa 220% de dano em um alvo.',
   'Quando o beat cai, entra em modo fúria. Dano bruto e sem freio.', false, 8),
  ('teto', 'Teto', 'Lorde da Tempestade', 'tempestade', 'lendaria', 33, 14, 125,
   'Tempestade de Flow', 'aoe', 110, 'Raios de flow atingem todos os inimigos com 110% de dano.',
   'Um flow tão rápido que vira tempestade. Ninguém fica de pé quando ele começa.', false, 9),
  ('matue', 'Matuê', 'Mestre do Tempo', 'cosmico', 'lendaria', 35, 16, 135,
   'Distorção Temporal', 'pierce', 200, 'Dobra o tempo: 200% de dano que ignora a defesa.',
   'Controla o tempo e o espaço da cena. O chefe final de qualquer jornada.', false, 10)
on conflict (id) do update set
  name = excluded.name, title = excluded.title, element = excluded.element, rarity = excluded.rarity,
  attack = excluded.attack, defense = excluded.defense, hp = excluded.hp,
  special_name = excluded.special_name, special_type = excluded.special_type,
  special_power = excluded.special_power, special_desc = excluded.special_desc,
  lore = excluded.lore, is_starter = excluded.is_starter, sort_order = excluded.sort_order;

-- Classes e frases conforme as artes oficiais das cartas.
update public.cards c set title = v.title, lore = v.lore
from (values
  ('klisman',      'Peso',              '“Muito dinheiro, pouco barulho.”'),
  ('phlnoturnboy', 'Plug',              '“Sempre no noturno, claridade é exceção.”'),
  ('alee',         'Melodia',           '“O tempo cura, mas a música faz viver.”'),
  ('leviano',      'Feiticeiro de Rua', '“Mesma essência, outro mundo.”'),
  ('teto',         'Poeta Astral',      '“De um mundo real para algo maior.”'),
  ('matue',        'Arcanista do Trap', '“Mesma essência, outro mundo.”'),
  ('fabgodamn',    'Berserker Caótico', '“Trap, arte, liberdade. Real até o fim.”'),
  ('stef',         'Estrategista',      '“Mesmo no caos, eu mantenho o foco.”'),
  ('reid',         'Artista',           '“Mesmo com tudo contra, eu ainda escolho sonhar.”'),
  ('fabin',        'Trap',              '“Disciplina é o que me mantém vivo.”')
) as v(id, title, lore)
where c.id = v.id;


insert into public.missions
  (id, title, description, guidance, category, difficulty, points, enemy_cards, enemy_level, reward_card_id, is_featured, sort_order)
values
  (1, 'Primeiro Freestyle',
   'Seu primeiro duelo no corre. Enfrente o Fabin num treino amistoso e mostre que você tem flow.',
   'Selecione até 3 cartas. Toque em uma carta sua para agir e em um inimigo para mirar. Ataques normais carregam o Hype; com 3 de Hype você solta o Especial.',
   'treino', 'facil', 50, array['fabin'], 1, 'stef', false, 1),
  (2, 'Duelo na Praça',
   'Uma roda se formou na praça. Reid e Fabin desafiam você para uma batalha 2 contra 3.',
   'Luz é forte contra Sombra. Vento é forte contra Terra: use o Leviano contra o Fabin.',
   'batalha', 'facil', 80, array['reid','fabin'], 1, 'klisman', true, 2),
  (3, 'Treino de Grave',
   'Aguente a pressão do grave pesado. Dois Klisman seguram a linha e não caem fácil.',
   'Terra é fraca contra Vento. Ataques que ignoram defesa (Flecha Sônica) brilham aqui.',
   'treino', 'medio', 100, array['klisman','klisman'], 1, null, false, 3),
  (4, 'Roda de Rima do Corre',
   'A roda de rima mais disputada da cidade. Stef e Leviano estão inspirados hoje.',
   'Cuidado com a Rajada Leve: carta atordoada perde a vez. Espalhe o dano e guarde Hype.',
   'batalha', 'medio', 120, array['stef','leviano','fabin'], 2, 'alee', false, 4),
  (5, 'Batalha da Madrugada',
   'Depois da meia-noite as regras mudam. Alee e Phlnoturnboy dominam as sombras.',
   'Sombra é fraca contra Luz: o Reid é sua melhor arma. Cure o time antes que o dreno vire o jogo.',
   'batalha', 'dificil', 180, array['alee','phlnoturnboy'], 2, 'phlnoturnboy', false, 5),
  (6, 'Torneio Estadual',
   'Três rounds, três rivais. Quem vencer o estadual ganha moral na cena inteira.',
   'Monte um time equilibrado: um curador, um que atordoa e um de dano alto.',
   'torneio', 'dificil', 220, array['alee','klisman','stef'], 2, 'fabgodamn', false, 6),
  (7, 'Fúria do 808',
   'O FabGoDamn entrou em modo berserker. O beat está alto demais para ser ignorado.',
   'Fogo é fraco contra Terra e Tempestade. Atordoe o berserker antes que a Fúria do 808 caia.',
   'chefe', 'dificil', 250, array['fabgodamn','reid'], 4, null, false, 7),
  (8, 'Festival do Trap',
   'O maior festival do ano. Só os melhores line-ups chegam ao palco principal.',
   'Os inimigos estão no nível 4. Suba de nível concluindo missões para fortalecer suas cartas.',
   'torneio', 'dificil', 300, array['phlnoturnboy','fabgodamn','klisman'], 4, null, false, 8),
  (9, 'Chefe: Lorde da Tempestade',
   'Raios cortam o céu. O Teto chegou com uma tempestade de flow e um exército de apoio.',
   'A Tempestade de Flow acerta o time todo. Mantenha a vida alta com Klisman ou Fabin.',
   'chefe', 'lendario', 400, array['teto','alee','stef'], 5, 'teto', false, 9),
  (10, 'Chefe Final: Mestre do Tempo',
   'O desafio final. Matuê dobra o tempo e convoca os mais fortes para defender o trono.',
   'Distorção Temporal ignora defesa. Derrube os aliados primeiro e use Gelo/Tempestade com sabedoria.',
   'chefe', 'lendario', 600, array['matue','teto','fabgodamn'], 4, 'matue', false, 10)
on conflict (id) do update set
  title = excluded.title, description = excluded.description, guidance = excluded.guidance,
  category = excluded.category, difficulty = excluded.difficulty, points = excluded.points,
  enemy_cards = excluded.enemy_cards, enemy_level = excluded.enemy_level,
  reward_card_id = excluded.reward_card_id, is_featured = excluded.is_featured,
  sort_order = excluded.sort_order;


insert into public.achievements
  (id, name, description, icon, condition_type, condition_value, condition_category, sort_order)
values
  ('primeira_rima',   'Primeira Rima',        'Venceu a primeira batalha da carreira.',          'mic',            'missions_completed', 1,    null,      1),
  ('mixtape',         'Mixtape Completa',     'Concluiu cinco missões.',                         'album',          'missions_completed', 5,    null,      2),
  ('turne',           'Turnê Nacional',       'Concluiu missões em três dias diferentes.',       'calendar',       'distinct_days',      3,    null,      3),
  ('rei_das_rodas',   'Rei das Rodas',        'Venceu três batalhas de rima.',                   'swords',         'category_completed', 3,    'batalha', 4),
  ('cacador_chefes',  'Caçador de Chefes',    'Derrotou dois chefes.',                           'skull',          'category_completed', 2,    'chefe',   5),
  ('disco_ouro',      'Disco de Ouro',        'Alcançou 500 pontos.',                            'gold',           'points',             500,  null,      6),
  ('disco_platina',   'Disco de Platina',     'Alcançou 1500 pontos.',                           'diamond',        'points',             1500, null,      7),
  ('colecionador',    'Colecionador',         'Possui 6 cartas na coleção.',                     'cards',          'cards_owned',        6,    null,      8),
  ('lineup_completo', 'Line-up Completo',     'Desbloqueou todas as 10 cartas.',                 'crown',          'cards_owned',        10,   null,      9),
  ('lenda',           'Lenda do Trap',        'Concluiu todas as 10 missões.',                   'trophy',         'missions_completed', 10,   null,      10)
on conflict (id) do update set
  name = excluded.name, description = excluded.description, icon = excluded.icon,
  condition_type = excluded.condition_type, condition_value = excluded.condition_value,
  condition_category = excluded.condition_category, sort_order = excluded.sort_order;


-- Usuários que já existiam antes deste script também ganham perfil e cartas iniciais.
insert into public.profiles (id, nickname)
select u.id,
       case when char_length(left(split_part(u.email, '@', 1), 20)) < 2
            then 'MC ' || split_part(u.email, '@', 1)
            else left(split_part(u.email, '@', 1), 20) end
  from auth.users u
on conflict (id) do nothing;

insert into public.user_cards (user_id, card_id)
select p.id, c.id from public.profiles p cross join public.cards c where c.is_starter
on conflict do nothing;
