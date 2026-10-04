-- =====================================================================
--  Migration 10 — Le coach peut corriger les données des adhérents
--  À exécuter dans Supabase → SQL Editor → New query → Run
--
--  Autorise le compte coach à modifier, depuis l'espace coach
--  (moniteur-groupe-polar.html → « Modifier / supprimer ») :
--    - les résultats du protocole (valeurs, point de test, date) ;
--    - le profil d'un adhérent (nom, prénom, cours, genre, naissance).
--  Les règles existantes (chaque adhérent gère ses propres données)
--  restent inchangées : ces règles s'ajoutent aux précédentes.
-- =====================================================================

drop policy if exists "protocol_test_results_update_coach" on public.protocol_test_results;
create policy "protocol_test_results_update_coach" on public.protocol_test_results
  for update using (public.is_coach()) with check (public.is_coach());

drop policy if exists "profiles_update_coach" on public.profiles;
create policy "profiles_update_coach" on public.profiles
  for update using (public.is_coach()) with check (public.is_coach());

-- Droits de table (sans effet s'ils existent déjà).
grant select, update on public.protocol_test_results to authenticated;
grant select, update on public.profiles to authenticated;
