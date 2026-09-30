-- =====================================================================
--  Migration 6 — Nom et cours obligatoires pour chaque adhérent
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après les migrations précédentes).
--
--  Ajoute le nom et le cours (Gironville, Milly, Boutigny) au profil,
--  pour que l'espace coach puisse regrouper les données par cours.
--  L'app oblige chaque adhérent à les renseigner (à l'inscription, et
--  à la prochaine connexion pour les comptes déjà existants).
-- =====================================================================

alter table public.profiles add column if not exists nom text;
alter table public.profiles add column if not exists cours text;

alter table public.profiles drop constraint if exists profiles_cours_check;
alter table public.profiles add constraint profiles_cours_check
  check (cours is null or cours in ('Gironville', 'Milly', 'Boutigny'));

-- Le trigger d'inscription enregistre aussi le nom et le cours saisis.
-- Une valeur de cours inattendue est ignorée (null) plutôt que de faire
-- échouer la création du compte ; l'app redemandera le cours.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, prenom, nom, cours, consent_at)
  values (
    new.id,
    new.email,
    coalesce(nullif(new.raw_user_meta_data ->> 'prenom', ''), split_part(new.email, '@', 1)),
    nullif(new.raw_user_meta_data ->> 'nom', ''),
    case when new.raw_user_meta_data ->> 'cours' in ('Gironville', 'Milly', 'Boutigny')
         then new.raw_user_meta_data ->> 'cours' end,
    (new.raw_user_meta_data ->> 'consent_at')::timestamptz
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
