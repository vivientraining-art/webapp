-- =====================================================================
--  Migration 3 — Protocole de test Force + Cardio
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après supabase-schema.sql et supabase-migration-2.sql).
--
--  Stocke les résultats bruts du protocole de test "Force + Cardio"
--  (préhension, pompes, wall-sit, rowing, RDL, AMRAP cardio), par
--  participant et par point de test (T0/T1/T2/T3). Aucun score
--  calculé ni normalisé — uniquement les valeurs brutes saisies.
--
--  Le test Ruffier existant reste séparé et n'est pas concerné par
--  cette migration.
-- =====================================================================

create table if not exists public.protocol_test_results (
  id             bigint generated always as identity primary key,
  participant_id uuid not null references auth.users (id) on delete cascade,
  coach_id       uuid not null references auth.users (id) on delete cascade,
  point_de_test  text not null check (point_de_test in ('T0', 'T1', 'T2', 'T3')),
  date_test      date not null default current_date,
  test_type      text not null check (test_type in ('grip', 'pompes', 'wallsit', 'rowing', 'rdl', 'amrap_cardio')),
  data           jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now()
);

-- Un seul résultat par participant / point de test / type de test :
-- ré-enregistrer (upsert) met à jour plutôt que de dupliquer.
create unique index if not exists protocol_test_results_unique
  on public.protocol_test_results (participant_id, point_de_test, test_type);

create index if not exists protocol_test_results_participant_idx
  on public.protocol_test_results (participant_id, point_de_test);

-- ------------------------------------------------------------------
-- Row Level Security — réservé au coach (protocole administré par
-- le coach pendant la séance, pas en auto-saisie par l'adhérent).
-- ------------------------------------------------------------------
alter table public.protocol_test_results enable row level security;

drop policy if exists "protocol_test_results_all" on public.protocol_test_results;
create policy "protocol_test_results_all" on public.protocol_test_results
  for all using (coach_id = auth.uid() and public.is_coach())
  with check (coach_id = auth.uid() and public.is_coach());

-- Permissions explicites (voir le vécu sur les tables de coaching
-- individuel : sans ça, erreur "permission denied for table").
grant select, insert, update, delete on public.protocol_test_results to authenticated;
grant usage, select on sequence public.protocol_test_results_id_seq to authenticated;
