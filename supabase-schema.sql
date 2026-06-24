-- =====================================================================
--  Espace adhérent — schéma Supabase (Postgres)
--  Application : Moniteur de groupe Polar H10 — Vivien Strudel
--
--  À exécuter UNE FOIS dans Supabase :
--    Dashboard → SQL Editor → New query → coller ce fichier → Run.
--
--  Ce script crée :
--    • profiles        : un profil par adhérent (lié à auth.users)
--    • measurements    : mesures saisies à la main (force, préhension, VO2max, cognitif)
--    • hr_sessions     : séances de fréquence cardiaque enregistrées via le Polar H10
--    • Row Level Security : chaque adhérent ne voit QUE ses données.
--      Le coach (profiles.role = 'coach') voit TOUT en lecture.
-- =====================================================================

-- ------------------------------------------------------------------
-- 1) Table des profils
-- ------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text,
  prenom      text,
  fc_max      integer default 190 check (fc_max between 120 and 230),
  sexe        text default 'H' check (sexe in ('H', 'F')),
  role        text not null default 'member' check (role in ('member', 'coach')),
  created_at  timestamptz not null default now()
);

-- ------------------------------------------------------------------
-- 2) Mesures saisies manuellement
--    type ∈ 'force' | 'grip' | 'vo2max' | 'cognitif'
--    data : contenu libre selon le type (jsonb), p. ex.
--      force    : { "exercice":"Squat", "kg":80, "reps":5, "e1rm":93 }
--      grip     : { "main":"D", "kg":42.5 }
--      vo2max   : { "sexe":"H", "fc_reco":140, "vo2max":45.2 }
--      cognitif : { "test":"pvt", "ms":275 }  (ou stroop / nback)
-- ------------------------------------------------------------------
create table if not exists public.measurements (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  type        text not null check (type in ('force', 'grip', 'vo2max', 'cognitif')),
  data        jsonb not null default '{}'::jsonb,
  recorded_at timestamptz not null default now()
);
create index if not exists measurements_user_idx on public.measurements (user_id, recorded_at desc);

-- ------------------------------------------------------------------
-- 3) Séances de fréquence cardiaque (capteur Polar)
--    zone_seconds : { "0":120, "1":300, ... "5":60 } secondes par zone
-- ------------------------------------------------------------------
create table if not exists public.hr_sessions (
  id           bigint generated always as identity primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  started_at   timestamptz not null,
  stopped_at   timestamptz not null,
  duration_s   integer not null default 0,
  fc_max       integer,
  hr_avg       integer,
  hr_min       integer,
  hr_peak      integer,
  rmssd        numeric,
  zone_seconds jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);
create index if not exists hr_sessions_user_idx on public.hr_sessions (user_id, started_at desc);

-- ------------------------------------------------------------------
-- 4) Création automatique du profil à l'inscription
-- ------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, prenom)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'prenom', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------------
-- 5) Fonction utilitaire : l'utilisateur courant est-il coach ?
--    SECURITY DEFINER pour éviter la récursion des politiques RLS.
-- ------------------------------------------------------------------
create or replace function public.is_coach()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'coach'
  );
$$;

-- ------------------------------------------------------------------
-- 6) Row Level Security
-- ------------------------------------------------------------------
alter table public.profiles     enable row level security;
alter table public.measurements enable row level security;
alter table public.hr_sessions  enable row level security;

-- ---- profiles ----
drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_self" on public.profiles
  for select using (id = auth.uid() or public.is_coach());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- ---- measurements ----
drop policy if exists "measurements_select" on public.measurements;
create policy "measurements_select" on public.measurements
  for select using (user_id = auth.uid() or public.is_coach());

drop policy if exists "measurements_insert" on public.measurements;
create policy "measurements_insert" on public.measurements
  for insert with check (user_id = auth.uid());

drop policy if exists "measurements_delete" on public.measurements;
create policy "measurements_delete" on public.measurements
  for delete using (user_id = auth.uid());

-- ---- hr_sessions ----
drop policy if exists "hr_select" on public.hr_sessions;
create policy "hr_select" on public.hr_sessions
  for select using (user_id = auth.uid() or public.is_coach());

drop policy if exists "hr_insert" on public.hr_sessions;
create policy "hr_insert" on public.hr_sessions
  for insert with check (user_id = auth.uid());

drop policy if exists "hr_delete" on public.hr_sessions;
create policy "hr_delete" on public.hr_sessions
  for delete using (user_id = auth.uid());

-- =====================================================================
--  APRÈS exécution : pour te désigner comme coach, lance (avec ton email) :
--
--    update public.profiles set role = 'coach'
--    where email = 'ton-email@exemple.fr';
--
--  (il faut t'être connecté au moins une fois pour que le profil existe)
-- =====================================================================
