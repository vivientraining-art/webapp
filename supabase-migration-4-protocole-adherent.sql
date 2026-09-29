-- =====================================================================
--  Migration 4 — Protocole de test en auto-saisie par l'adhérent
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après supabase-migration-3-protocole-force-cardio.sql).
--
--  Le protocole "Force + Cardio" est maintenant passé directement par
--  l'adhérent dans son espace personnel (plus par le coach dans un
--  outil séparé). Cette migration adapte les règles d'accès en
--  conséquence : chaque adhérent gère ses propres résultats, le coach
--  garde une vue en lecture sur tout le monde.
-- =====================================================================

-- coach_id n'est plus renseigné en auto-saisie (personne n'"administre"
-- le test au sens strict) : la colonne devient facultative.
alter table public.protocol_test_results alter column coach_id drop not null;

drop policy if exists "protocol_test_results_all" on public.protocol_test_results;

create policy "protocol_test_results_select" on public.protocol_test_results
  for select using (participant_id = auth.uid() or public.is_coach());

create policy "protocol_test_results_insert" on public.protocol_test_results
  for insert with check (participant_id = auth.uid());

create policy "protocol_test_results_update" on public.protocol_test_results
  for update using (participant_id = auth.uid()) with check (participant_id = auth.uid());

create policy "protocol_test_results_delete" on public.protocol_test_results
  for delete using (participant_id = auth.uid());

-- Les permissions de table accordées en migration 3 (grant select,
-- insert, update, delete ... to authenticated) restent valables et
-- couvrent ces nouvelles règles — rien à réaccorder.
