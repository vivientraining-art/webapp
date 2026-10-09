-- =====================================================================
--  Migration 14 — Sécurité : un adhérent ne peut plus se donner le rôle coach
--  À exécuter dans Supabase → SQL Editor → New query → Run
--
--  Problème corrigé : la règle « chacun peut modifier son profil » portait sur
--  toutes les colonnes, y compris « role ». Un adhérent un peu bricoleur pouvait
--  se mettre « coach » depuis son navigateur et voir les données de tout le monde.
--
--  Désormais, le rôle ne change que depuis le SQL Editor (ou le serveur) :
--    update public.profiles set role = 'coach' where email = '…';
--  Les adhérents et le coach gardent le droit de modifier les autres champs.
--  Sans risque, peut être relancée.
-- =====================================================================

create or replace function public.protege_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- auth.uid() est vide pour le SQL Editor, l'inscription (trigger auth) et le serveur :
  -- seuls les appels faits par un utilisateur connecté sont contrôlés.
  if auth.uid() is not null then
    if tg_op = 'INSERT' and coalesce(new.role, 'member') <> 'member' then
      raise exception 'Le rôle ne peut pas être choisi par l''application.';
    elsif tg_op = 'UPDATE' and new.role is distinct from old.role then
      raise exception 'Le rôle ne peut pas être modifié par l''application.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protege_role on public.profiles;
create trigger profiles_protege_role
  before insert or update on public.profiles
  for each row execute function public.protege_role();

-- Vérification : doit afficher la ligne du trigger
select tgname from pg_trigger where tgname = 'profiles_protege_role';
