-- =====================================================================
--  Migration 17 — Bilan du groupe visible par les adhérents
--  À exécuter dans Supabase → SQL Editor → New query → Run
--
--  Les adhérents ne peuvent pas lire les résultats des autres (et c'est voulu).
--  La fonction stats_groupe() calcule dans la base des statistiques ANONYMES
--  — moyennes, écarts-types, part de progrès — pour le cours de l'adhérent et
--  pour toute l'association, sans jamais renvoyer de valeur individuelle, et
--  seulement à partir de 5 personnes (sinon on devinerait qui a fait quoi).
--  Le coach peut ouvrir ou fermer ce bilan (table « reglages »).
--  Renvoie aussi effectif, femmes · hommes et âge moyen (page bilan-asso.html) :
--  si tu l'avais déjà exécutée, relance-la pour les avoir.
--  Sans risque, peut être relancée.
-- =====================================================================

-- Réglages simples modifiables par le coach
create table if not exists public.reglages (
  cle     text primary key,
  valeur  jsonb not null default '{}'::jsonb,
  maj     timestamptz not null default now()
);
alter table public.reglages enable row level security;
drop policy if exists "reglages_select" on public.reglages;
create policy "reglages_select" on public.reglages for select using (auth.uid() is not null);
drop policy if exists "reglages_insert_coach" on public.reglages;
create policy "reglages_insert_coach" on public.reglages for insert with check (public.is_coach());
drop policy if exists "reglages_update_coach" on public.reglages;
create policy "reglages_update_coach" on public.reglages for update using (public.is_coach()) with check (public.is_coach());
revoke all on public.reglages from anon;
grant select, insert, update on public.reglages to authenticated;
insert into public.reglages (cle, valeur) values ('stats_groupe', '{"ouvert": true}') on conflict (cle) do nothing;

-- Conversion sans erreur d'un texte en nombre
create or replace function public.num_ou_null(t text) returns numeric
language plpgsql immutable as $$
begin
  return t::numeric;
exception when others then
  return null;
end;
$$;

create or replace function public.stats_groupe()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  k_min constant int := 5;   -- en dessous de 5 personnes, rien n'est affiché
  mon_cours text;
  res jsonb;
begin
  if auth.uid() is null then
    raise exception 'connexion requise';
  end if;
  if coalesce((select (valeur ->> 'ouvert')::boolean from public.reglages where cle = 'stats_groupe'), true) = false then
    return jsonb_build_object('ouvert', false);
  end if;
  select cours into mon_cours from public.profiles where id = auth.uid();

  with v as (   -- une valeur par adhérent, point de test et indicateur
    select r.participant_id as uid, p.cours, p.sexe, date_part('year', age(current_date, p.date_naissance))::int as age,
           r.point_de_test as pt, i.cle, i.val, i.cond
    from public.protocol_test_results r
    join public.profiles p on p.id = r.participant_id and p.role <> 'coach'
    cross join lateral (
      select 'prehension' as cle, greatest(num_ou_null(r.data ->> 'force_main_gauche_kg'), num_ou_null(r.data ->> 'force_main_droite_kg')) as val, '' as cond
        where r.test_type = 'grip'
      union all
      select 'pompes:' || case when r.data ->> 'pompes_variante' = 'classique' then 'jambes tendues' else coalesce(r.data ->> 'pompes_variante', '?') end,
             num_ou_null(r.data ->> 'pompes_reps'), '' where r.test_type = 'pompes'
      union all
      select 'wallsit', num_ou_null(r.data ->> 'wallsit_secondes'),
             case when coalesce(r.data ->> 'wallsit_plafond_atteint', '') = 'true' then 'plafond' else '' end where r.test_type = 'wallsit'
      union all
      select 'amrap_tours', num_ou_null(r.data ->> 'amrap_tours_complets'),
             case when coalesce(r.data ->> 'no_impact', '') = 'true' then 'no_impact' else '' end
        where r.test_type = 'amrap_cardio' and coalesce(r.data ->> 'duree_min', '10') = '20'
      union all
      select 'amrap_intensite', num_ou_null(r.data ->> 'intensite_pct'), ''
        where r.test_type = 'amrap_cardio' and coalesce(r.data ->> 'fc_amrap_valide', 'true') <> 'false'
      union all
      select 'hrr60', num_ou_null(r.data ->> 'hrr60'), '' where r.test_type = 'rfc' and coalesce(r.data ->> 'valide', 'true') <> 'false'
      union all
      select 'squat', num_ou_null(r.data ->> 'squat_1rm'), '' where r.test_type = 'force_max'
      union all
      select 'dc', num_ou_null(r.data ->> 'dc_1rm'), '' where r.test_type = 'force_max'
      union all
      select 'rdl', num_ou_null(r.data ->> 'rdl_1rm'), '' where r.test_type = 'force_max'
    ) i
    where i.val is not null
  ),
  portee as (   -- chaque valeur compte pour son cours et pour toute l'association
    select 'asso' as scope, v.* from v
    union all
    select 'cours', v.* from v where mon_cours is not null and v.cours = mon_cours
  ),
  gens as (select distinct scope, uid, sexe, age from portee),
  profil as (   -- qui a été testé : effectif, femmes / hommes, âge (à partir de 5 personnes)
    select scope, count(*) as personnes, count(*) filter (where sexe = 'F') as femmes, count(*) filter (where sexe = 'H') as hommes,
           round(avg(age)) as age_moyen, round(stddev_samp(age)) as age_ecart_type
    from gens group by scope having count(*) >= k_min
  ),
  stats as (
    select scope, cle, pt, count(*) as n, round(avg(val), 1) as moyenne, round(stddev_samp(val), 1) as ecart_type
    from portee group by scope, cle, pt having count(*) >= k_min
  ),
  paires as (   -- premier et dernier test de chaque adhérent, pour chaque indicateur
    select scope, uid, cle,
           (array_agg(val order by pt))[1] as v0, (array_agg(val order by pt desc))[1] as v1,
           (array_agg(cond order by pt))[1] as c0, (array_agg(cond order by pt desc))[1] as c1
    from portee where cle <> 'amrap_intensite'
    group by scope, uid, cle having count(*) >= 2
  ),
  evo as (   -- même règle que la vue « Progrès » du coach : variation au-delà de la variabilité normale du test
    select scope, cle, v1 - v0 as d,
           case when cle = 'hrr60' then 8
                when cle = 'prehension' then greatest(2, abs(v0) * 0.10)
                when cle like 'pompes:%' then greatest(2, abs(v0) * 0.15)
                when cle = 'wallsit' then greatest(10, abs(v0) * 0.20)
                when cle = 'amrap_tours' then greatest(1, abs(v0) * 0.08)
                else greatest(2.5, abs(v0) * 0.10) end as seuil
    from paires
    where not (cle = 'wallsit' and c0 = 'plafond') and not (cle = 'amrap_tours' and c0 <> c1)
  ),
  evo_agg as (
    select scope, cle, count(*) as n, round(avg(d), 1) as variation_moyenne,
           count(*) filter (where d >= seuil) as progres, count(*) filter (where d <= -seuil) as baisse,
           count(*) filter (where d > -seuil and d < seuil) as stable
    from evo group by scope, cle having count(*) >= k_min
  )
  select jsonb_build_object(
    'ouvert', true, 'mon_cours', mon_cours, 'k_min', k_min, 'calcule_le', now(),
    'profil', coalesce((select jsonb_agg(to_jsonb(g) order by g.scope) from profil g), '[]'::jsonb),
    'stats', coalesce((select jsonb_agg(to_jsonb(s) order by s.scope, s.cle, s.pt) from stats s), '[]'::jsonb),
    'evolution', coalesce((select jsonb_agg(to_jsonb(e) order by e.scope, e.cle) from evo_agg e), '[]'::jsonb)
  ) into res;
  return res;
end;
$$;
revoke all on function public.stats_groupe() from public, anon;
grant execute on function public.stats_groupe() to authenticated;

-- Vérification : doit afficher « true » (bilan ouvert)
select valeur ->> 'ouvert' as bilan_ouvert from public.reglages where cle = 'stats_groupe';
