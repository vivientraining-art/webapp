-- =====================================================================
--  Migration 3 — Coaching individuel
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après supabase-schema.sql et supabase-migration-2.sql, qui doivent
--  déjà être installés).
--
--  Ajoute la gestion des clients suivis en individuel : fréquence
--  cardiaque par séance, tonnage et 1RM des exercices de renforcement
--  musculaire. Ces clients sont propres au coach — ils n'ont pas de
--  compte ni de connexion, c'est toi qui saisis tout pendant/après
--  la séance.
-- =====================================================================

-- ------------------------------------------------------------------
-- 1) Clients suivis en individuel (roster du coach)
-- ------------------------------------------------------------------
create table if not exists public.coaching_clients (
  id          bigint generated always as identity primary key,
  coach_id    uuid not null references auth.users (id) on delete cascade,
  nom         text not null,
  notes       text,
  fc_max      integer not null default 190 check (fc_max between 120 and 230),
  actif       boolean not null default true,
  created_at  timestamptz not null default now()
);
create index if not exists coaching_clients_coach_idx on public.coaching_clients (coach_id, actif);

-- ------------------------------------------------------------------
-- 2) Séances individuelles (résumé fréquence cardiaque + durée)
-- ------------------------------------------------------------------
create table if not exists public.coaching_sessions (
  id           bigint generated always as identity primary key,
  client_id    bigint not null references public.coaching_clients (id) on delete cascade,
  coach_id     uuid not null references auth.users (id) on delete cascade,
  started_at   timestamptz not null default now(),
  duration_s   integer,
  hr_avg       integer,
  hr_min       integer,
  hr_peak      integer,
  rmssd        numeric,
  zone_seconds jsonb not null default '{}'::jsonb,
  notes        text,
  created_at   timestamptz not null default now()
);
create index if not exists coaching_sessions_client_idx on public.coaching_sessions (client_id, started_at desc);

-- ------------------------------------------------------------------
-- 3) Séries de renforcement musculaire (tonnage, 1RM estimée)
--    tonnage = kg × reps × séries · e1rm = formule d'Epley
-- ------------------------------------------------------------------
create table if not exists public.strength_sets (
  id          bigint generated always as identity primary key,
  client_id   bigint not null references public.coaching_clients (id) on delete cascade,
  session_id  bigint references public.coaching_sessions (id) on delete cascade,
  coach_id    uuid not null references auth.users (id) on delete cascade,
  exercice    text not null,
  kg          numeric not null check (kg > 0),
  reps        integer not null check (reps > 0),
  series      integer not null default 1 check (series > 0),
  tonnage     numeric not null,
  e1rm        numeric not null,
  recorded_at timestamptz not null default now()
);
create index if not exists strength_sets_client_idx on public.strength_sets (client_id, recorded_at desc);
create index if not exists strength_sets_session_idx on public.strength_sets (session_id);

-- ------------------------------------------------------------------
-- 4) Row Level Security — réservé au coach propriétaire des données
--    (réutilise la fonction public.is_coach() de supabase-schema.sql)
-- ------------------------------------------------------------------
alter table public.coaching_clients  enable row level security;
alter table public.coaching_sessions enable row level security;
alter table public.strength_sets     enable row level security;

drop policy if exists "coaching_clients_all" on public.coaching_clients;
create policy "coaching_clients_all" on public.coaching_clients
  for all using (coach_id = auth.uid() and public.is_coach())
  with check (coach_id = auth.uid() and public.is_coach());

drop policy if exists "coaching_sessions_all" on public.coaching_sessions;
create policy "coaching_sessions_all" on public.coaching_sessions
  for all using (coach_id = auth.uid() and public.is_coach())
  with check (coach_id = auth.uid() and public.is_coach());

drop policy if exists "strength_sets_all" on public.strength_sets;
create policy "strength_sets_all" on public.strength_sets
  for all using (coach_id = auth.uid() and public.is_coach())
  with check (coach_id = auth.uid() and public.is_coach());

-- =====================================================================
--  Ce script ne fait rien tant que ton compte n'a pas le rôle 'coach'
--  (voir étape 6 de GUIDE-ESPACE-ADHERENT.md) :
--
--    update public.profiles set role = 'coach'
--    where email = 'ton-email@exemple.fr';
-- =====================================================================
