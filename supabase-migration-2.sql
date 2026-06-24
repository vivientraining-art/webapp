-- =====================================================================
--  Migration 2 — Espace adhérent
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après supabase-schema.sql, qui doit déjà être installé).
--
--  Ajoute : récupération cardiaque (HRR), consentement RGPD,
--           suppression de compte par l'adhérent.
-- =====================================================================

-- 1) Autoriser le type 'hrr' (récupération cardiaque) dans measurements
alter table public.measurements drop constraint if exists measurements_type_check;
alter table public.measurements add constraint measurements_type_check
  check (type in ('force', 'grip', 'vo2max', 'cognitif', 'hrr'));

-- 2) Consentement RGPD (date à laquelle l'adhérent a accepté)
alter table public.profiles add column if not exists consent_at timestamptz;

-- 3) Le trigger enregistre aussi le consentement donné à l'inscription
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, prenom, consent_at)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'prenom', split_part(new.email, '@', 1)),
    (new.raw_user_meta_data ->> 'consent_at')::timestamptz
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- 4) Suppression du compte par l'adhérent lui-même (droit RGPD à l'effacement)
--    SECURITY DEFINER : la fonction s'exécute avec les droits du propriétaire
--    et supprime l'utilisateur dans auth.users. Les données liées
--    (profiles, measurements, hr_sessions) partent en cascade.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
