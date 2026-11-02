-- =====================================================================
--  Migration 16 — Corbeille : récupérer une suppression faite par erreur
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après la migration 13, qui ajoute la colonne « qualite » des séances)
--
--  Chaque résultat de test ou séance capteur supprimé (par le coach ou par
--  l'adhérent) est copié dans la table « corbeille » et peut être restauré
--  par le coach pendant 60 jours, puis il est effacé définitivement.
--  Exception : quand un COMPTE est supprimé (droit à l'effacement, doublon),
--  rien n'est gardé.
--  Sans risque, peut être relancée.
-- =====================================================================

create table if not exists public.corbeille (
  id              bigint generated always as identity primary key,
  table_origine   text not null,
  ligne           jsonb not null,          -- copie complète de la ligne supprimée
  participant_id  uuid,
  supprime_le     timestamptz not null default now(),
  supprime_par    uuid                     -- qui a supprimé (vide : SQL Editor)
);
create index if not exists corbeille_date_idx on public.corbeille (supprime_le desc);

alter table public.corbeille enable row level security;
drop policy if exists "corbeille_select_coach" on public.corbeille;
create policy "corbeille_select_coach" on public.corbeille for select using (public.is_coach());
drop policy if exists "corbeille_delete_coach" on public.corbeille;
create policy "corbeille_delete_coach" on public.corbeille for delete using (public.is_coach());
revoke all on public.corbeille from anon, authenticated;
grant select, delete on public.corbeille to authenticated;   -- seul le trigger y écrit

-- Copie dans la corbeille à chaque suppression
create or replace function public.vers_corbeille()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  j jsonb := to_jsonb(old);
  uid uuid := coalesce(j ->> 'participant_id', j ->> 'user_id')::uuid;
begin
  -- compte supprimé (droit à l'effacement, doublon) : rien n'est gardé
  if uid is not null and not exists (select 1 from auth.users where id = uid) then
    return old;
  end if;
  insert into public.corbeille (table_origine, ligne, participant_id, supprime_par)
  values (tg_table_name, j, uid, auth.uid());
  delete from public.corbeille where supprime_le < now() - interval '60 days';
  return old;
end;
$$;

drop trigger if exists protocol_test_results_corbeille on public.protocol_test_results;
create trigger protocol_test_results_corbeille after delete on public.protocol_test_results
  for each row execute function public.vers_corbeille();
drop trigger if exists hr_sessions_corbeille on public.hr_sessions;
create trigger hr_sessions_corbeille after delete on public.hr_sessions
  for each row execute function public.vers_corbeille();

-- Restauration par le coach. « remplacer » : si un résultat existe déjà pour ce point de test,
-- il est remplacé (et part lui-même dans la corbeille).
create or replace function public.restaurer_corbeille(cible bigint, remplacer boolean default false)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  c public.corbeille%rowtype;
  j jsonb;
begin
  if not public.is_coach() then
    raise exception 'réservé au coach';
  end if;
  select * into c from public.corbeille where id = cible;
  if not found then
    raise exception 'introuvable';
  end if;
  j := c.ligne;
  if c.participant_id is null or not exists (select 1 from auth.users where id = c.participant_id) then
    raise exception 'compte_supprime';
  end if;
  if c.table_origine = 'protocol_test_results' then
    if exists (select 1 from public.protocol_test_results where participant_id = c.participant_id
               and point_de_test = j ->> 'point_de_test' and test_type = j ->> 'test_type') then
      if not remplacer then
        raise exception 'existe_deja';
      end if;
      delete from public.protocol_test_results where participant_id = c.participant_id
        and point_de_test = j ->> 'point_de_test' and test_type = j ->> 'test_type';
    end if;
    insert into public.protocol_test_results (participant_id, coach_id, point_de_test, date_test, test_type, data, created_at)
    values (c.participant_id, nullif(j ->> 'coach_id', '')::uuid, j ->> 'point_de_test', (j ->> 'date_test')::date,
            j ->> 'test_type', coalesce(j -> 'data', '{}'::jsonb), coalesce((j ->> 'created_at')::timestamptz, now()));
  elsif c.table_origine = 'hr_sessions' then
    insert into public.hr_sessions (user_id, started_at, stopped_at, duration_s, fc_max, hr_avg, hr_min, hr_peak, rmssd, zone_seconds, qualite, created_at)
    select user_id, started_at, stopped_at, coalesce(duration_s, 0), fc_max, hr_avg, hr_min, hr_peak, rmssd,
           coalesce(zone_seconds, '{}'::jsonb), qualite, coalesce(created_at, now())
    from jsonb_populate_record(null::public.hr_sessions, j);
  else
    raise exception 'type non restaurable';
  end if;
  delete from public.corbeille where id = cible;
  return 'restauré';
end;
$$;
revoke all on function public.restaurer_corbeille(bigint, boolean) from public, anon;
grant execute on function public.restaurer_corbeille(bigint, boolean) to authenticated;

-- Vérification : doit afficher les 2 triggers
select tgname from pg_trigger where tgname in ('protocol_test_results_corbeille', 'hr_sessions_corbeille');
