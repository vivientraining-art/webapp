-- =====================================================================
--  Migration 8 — Le coach peut supprimer des tests
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après la migration 7).
--
--  Ajoute un droit de suppression réservé au compte coach, sur les
--  résultats du protocole, les séances capteur et les mesures, depuis
--  l'espace coach (moniteur-groupe-polar.html → « Supprimer des tests »).
--  Les règles existantes (chaque adhérent gère ses propres données)
--  restent inchangées : ces règles s'ajoutent aux précédentes.
-- =====================================================================

drop policy if exists "protocol_test_results_delete_coach" on public.protocol_test_results;
create policy "protocol_test_results_delete_coach" on public.protocol_test_results
  for delete using (public.is_coach());

drop policy if exists "hr_delete_coach" on public.hr_sessions;
create policy "hr_delete_coach" on public.hr_sessions
  for delete using (public.is_coach());

drop policy if exists "measurements_delete_coach" on public.measurements;
create policy "measurements_delete_coach" on public.measurements
  for delete using (public.is_coach());

-- Droits de table (sans effet s'ils existent déjà).
grant select, delete on public.protocol_test_results to authenticated;
grant select, delete on public.hr_sessions to authenticated;
grant select, delete on public.measurements to authenticated;
