-- =====================================================================
--  Migration 7 — Genre, date de naissance et FC max de Tanaka
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après la migration 6).
--
--  L'âge n'est pas stocké tel quel (il changerait chaque année) : on
--  enregistre la date de naissance, et l'âge est calculé à la volée.
--  Le genre utilise la colonne "sexe" déjà existante (H / F).
--
--  FC max théorique = 208 − 0,7 × âge
--  Tanaka H, Monahan KD, Seals DR. Age-predicted maximal heart rate
--  revisited. J Am Coll Cardiol. 2001;37(1):153-156.
--  doi:10.1016/S0735-1097(00)01054-8
-- =====================================================================

alter table public.profiles add column if not exists date_naissance date;

alter table public.profiles drop constraint if exists profiles_date_naissance_check;
alter table public.profiles add constraint profiles_date_naissance_check
  check (date_naissance is null or date_naissance > date '1900-01-01');

-- FC max théorique de Tanaka pour une date de naissance donnée.
create or replace function public.fc_max_tanaka(naissance date)
returns integer
language sql
stable
as $$
  select round(208 - 0.7 * extract(year from age(current_date, naissance)))::integer
$$;

grant execute on function public.fc_max_tanaka(date) to authenticated;

-- Le trigger d'inscription enregistre aussi le genre, la date de
-- naissance et la FC max de Tanaka. Une valeur invalide est ignorée
-- (null) plutôt que de faire échouer la création du compte ; l'app
-- redemandera l'information à la connexion.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  naissance date;
begin
  if new.raw_user_meta_data ->> 'date_naissance' ~ '^\d{4}-\d{2}-\d{2}$' then
    begin
      naissance := (new.raw_user_meta_data ->> 'date_naissance')::date;
    exception when others then
      naissance := null;
    end;
  end if;

  insert into public.profiles (id, email, prenom, nom, cours, sexe, date_naissance, fc_max, consent_at)
  values (
    new.id,
    new.email,
    coalesce(nullif(new.raw_user_meta_data ->> 'prenom', ''), split_part(new.email, '@', 1)),
    nullif(new.raw_user_meta_data ->> 'nom', ''),
    case when new.raw_user_meta_data ->> 'cours' in ('Gironville', 'Milly', 'Boutigny')
         then new.raw_user_meta_data ->> 'cours' end,
    case when new.raw_user_meta_data ->> 'sexe' in ('H', 'F')
         then new.raw_user_meta_data ->> 'sexe' else 'H' end,
    naissance,
    case when naissance is not null and public.fc_max_tanaka(naissance) between 120 and 230
         then public.fc_max_tanaka(naissance) else 190 end,
    (new.raw_user_meta_data ->> 'consent_at')::timestamptz
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Aucun autre droit à accorder : les permissions sur "profiles" sont
-- déjà en place (chaque adhérent modifie son profil, le coach lit tout).
