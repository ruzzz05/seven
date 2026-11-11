-- ============================================================
-- SEVEN — esquema v1 (ver docs/05-Backend-Schema.md)
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- Perfiles ----------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nickname    text unique check (nickname ~ '^[A-Za-z0-9]{3,12}$'),
  created_at  timestamptz not null default now()
);

-- ---------- Partidas ----------
create type public.game_mode as enum ('normal', 'hardcore');
create type public.run_status as enum ('started', 'valid', 'rejected', 'abandoned');

create table public.runs (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles(id) on delete cascade,
  mode           public.game_mode not null,
  initial_board  smallint[] not null
                   check (array_length(initial_board, 1) = 4
                          and initial_board <@ array[1,2,3,4,5,6,7,8,9]::smallint[]),
  moves          jsonb not null default '[]'::jsonb,
  time_ms        integer check (time_ms is null or time_ms > 0),
  status         public.run_status not null default 'started',
  started_at     timestamptz not null default now(),
  finished_at    timestamptz,
  created_at     timestamptz not null default now(),
  constraint finished_consistent check (
    (status = 'valid' and time_ms is not null and finished_at is not null)
    or status <> 'valid'
  )
);

create index runs_user_idx on public.runs (user_id, created_at desc);

create index runs_leaderboard_idx
  on public.runs (mode, time_ms)
  where status = 'valid';

-- ---------- Vistas ----------
create or replace view public.best_times as
select distinct on (r.user_id, r.mode)
  r.user_id,
  r.mode,
  r.time_ms,
  r.id as run_id,
  p.nickname
from public.runs r
join public.profiles p on p.id = r.user_id
where r.status = 'valid' and p.nickname is not null
order by r.user_id, r.mode, r.time_ms asc;

-- ---------- Funciones de ranking ----------
create or replace function public.get_leaderboard(
  p_mode   public.game_mode,
  p_limit  int default 100,
  p_offset int default 0
)
returns table (position bigint, nickname text, time_ms int, user_id uuid)
language sql stable security definer set search_path = public as $$
  select
    row_number() over (order by bt.time_ms asc, bt.run_id asc) as position,
    bt.nickname,
    bt.time_ms,
    bt.user_id
  from public.best_times bt
  where bt.mode = p_mode
  order by bt.time_ms asc, bt.run_id asc
  limit least(p_limit, 100) offset p_offset;
$$;

create or replace function public.get_my_rank(p_mode public.game_mode)
returns table (position bigint, time_ms int)
language sql stable security definer set search_path = public as $$
  with ranked as (
    select
      row_number() over (order by bt.time_ms asc, bt.run_id asc) as position,
      bt.user_id,
      bt.time_ms
    from public.best_times bt
    where bt.mode = p_mode
  )
  select position, time_ms from ranked where user_id = auth.uid();
$$;

-- ---------- Row Level Security ----------
alter table public.profiles enable row level security;
alter table public.runs     enable row level security;

create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);
create policy profiles_insert_own on public.profiles
  for insert with check (auth.uid() = id);
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy runs_select_own on public.runs
  for select using (auth.uid() = user_id);

-- Escritura de runs solo vía Edge Functions (service role).
revoke insert, update, delete on public.runs from anon, authenticated;

grant select on public.best_times to anon, authenticated;
grant execute on function public.get_leaderboard(public.game_mode, int, int) to anon, authenticated;
grant execute on function public.get_my_rank(public.game_mode) to authenticated;
