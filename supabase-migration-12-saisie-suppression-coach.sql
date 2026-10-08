-- =====================================================================
--  Migration 12 — Le coach peut saisir des résultats et supprimer un compte
--  À exécuter dans Supabase → SQL Editor → New query → Run
--
--  1. Saisie : le compte coach peut ajouter des résultats du protocole
--     pour un adhérent (« + Saisir des résultats ») : adhérent venu sans
--     téléphone, valeur oubliée (FC de fin d'effort, FC à 2 min…).
--  2. Suppression : le compte coach peut supprimer le compte d'un
--     adhérent (doublon, inscription par erreur) depuis la vue
--     « Inscrits ». Toutes ses données partent avec (définitif).
--     Un compte coach ne peut pas être supprimé de cette façon.
--  Les règles existantes restent inchangées. Sans risque, peut être relancée.
-- =====================================================================

-- 1. Saisie de résultats par le coach
drop policy if exists "protocol_test_results_insert_coach" on public.protocol_test_results;
create policy "protocol_test_results_insert_coach" on public.protocol_test_results
  for insert with check (public.is_coach());

grant select, insert, update on public.protocol_test_results to authenticated;

-- 2. Suppression d'un compte adhérent par le coach
create or replace function public.coach_delete_user(cible uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.is_coach() then
    raise exception 'réservé au coach';
  end if;
  if cible = auth.uid() or exists (select 1 from public.profiles where id = cible and role = 'coach') then
    raise exception 'un compte coach ne peut pas être supprimé ici';
  end if;
  -- profil, résultats, séances et mesures partent en cascade
  delete from auth.users where id = cible;
end;
$$;

revoke all on function public.coach_delete_user(uuid) from public, anon;
grant execute on function public.coach_delete_user(uuid) to authenticated;
