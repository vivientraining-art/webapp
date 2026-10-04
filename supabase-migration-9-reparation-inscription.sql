-- =====================================================================
--  Migration 9 — Réparation de la création de compte
--  À exécuter dans Supabase → SQL Editor → New query → Run
--
--  Corrige l'erreur « Database error saving new user » à l'inscription.
--  Script sans risque, exécutable même si certaines migrations
--  précédentes (2, 6, 7) ont déjà été passées : tout ce qui manque est
--  ajouté, rien n'est supprimé.
--
--  Surtout : la création du profil ne peut plus bloquer l'inscription.
--  Si une donnée pose problème, un profil minimal est créé et l'app
--  redemande les informations manquantes à la première connexion.
-- =====================================================================

-- 1. Colonnes du profil (migrations 2, 6 et 7)
alter table public.profiles add column if not exists consent_at timestamptz;
alter table public.profiles add column if not exists nom text;
alter table public.profiles add column if not exists cours text;
alter table public.profiles add column if not exists date_naissance date;

alter table public.profiles drop constraint if exists profiles_cours_check;
alter table public.profiles add constraint profiles_cours_check
  check (cours is null or cours in ('Gironville', 'Milly', 'Boutigny'));

alter table public.profiles drop constraint if exists profiles_date_naissance_check;
alter table public.profiles add constraint profiles_date_naissance_check
  check (date_naissance is null or date_naissance > date '1900-01-01');

-- 2. FC max de Tanaka (2001) : 208 − 0,7 × âge
create or replace function public.fc_max_tanaka(naissance date)
returns integer
language sql
stable
as $$
  select round(208 - 0.7 * extract(year from age(current_date, naissance)))::integer
$$;
grant execute on function public.fc_max_tanaka(date) to authenticated;

-- 3. Création du profil à l'inscription — ne fait jamais échouer l'inscription
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  naissance date;
  fcmax integer := 190;
  consent timestamptz;
begin
  begin
    if meta ->> 'date_naissance' ~ '^\d{4}-\d{2}-\d{2}$' then
      naissance := (meta ->> 'date_naissance')::date;
      if naissance <= date '1900-01-01' or naissance > current_date then naissance := null; end if;
    end if;
  exception when others then naissance := null;
  end;
  if naissance is not null then
    fcmax := public.fc_max_tanaka(naissance);
    if fcmax not between 120 and 230 then fcmax := 190; end if;
  end if;
  begin
    consent := (meta ->> 'consent_at')::timestamptz;
  exception when others then consent := null;
  end;

  begin
    insert into public.profiles (id, email, prenom, nom, cours, sexe, date_naissance, fc_max, consent_at)
    values (
      new.id,
      new.email,
      coalesce(nullif(meta ->> 'prenom', ''), split_part(new.email, '@', 1)),
      nullif(meta ->> 'nom', ''),
      case when meta ->> 'cours' in ('Gironville', 'Milly', 'Boutigny') then meta ->> 'cours' end,
      case when meta ->> 'sexe' in ('H', 'F') then meta ->> 'sexe' else 'H' end,
      naissance,
      fcmax,
      consent
    )
    on conflict (id) do nothing;
  exception when others then
    -- secours : profil minimal, complété par l'adhérent à sa connexion
    begin
      insert into public.profiles (id, email) values (new.id, new.email) on conflict (id) do nothing;
    exception when others then
      raise warning 'handle_new_user : profil non créé pour % (%)', new.email, sqlerrm;
    end;
  end;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4. Si le profil manque malgré tout, l'app peut le créer elle-même
drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self" on public.profiles
  for insert with check (id = auth.uid());

grant select, insert, update on public.profiles to authenticated;

-- 5. Vérification : doit afficher les 4 colonnes ajoutées
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
  and column_name in ('consent_at', 'nom', 'cours', 'date_naissance')
order by column_name;
