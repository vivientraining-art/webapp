-- =====================================================================
--  Migration 13 — Questionnaire avant test et qualité du signal
--  À exécuter dans Supabase → SQL Editor → New query → Run
--
--  1. Autorise le type de résultat « questionnaire » (sommeil, fatigue,
--     malade, date et heure de la séance), rempli avant chaque passation.
--  2. Ajoute à chaque séance capteur un bilan de qualité du signal
--     (% de données valides, artefacts, coupures, signal plat, FC max
--     retenue et sa source).
--  Sans risque, peut être relancée.
-- =====================================================================

-- 1. Type de résultat « questionnaire » (même méthode que la migration 5)
do $$
declare
  cname text;
begin
  for cname in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_attribute att on att.attrelid = rel.oid and att.attnum = any(con.conkey)
    where rel.relname = 'protocol_test_results' and con.contype = 'c' and att.attname = 'test_type'
  loop
    execute format('alter table public.protocol_test_results drop constraint %I', cname);
  end loop;
end $$;

alter table public.protocol_test_results add constraint protocol_test_results_test_type_check
  check (test_type in ('grip', 'pompes', 'wallsit', 'rowing', 'rdl', 'amrap_cardio', 'rfc', 'questionnaire'));

-- 2. Qualité du signal de chaque séance capteur
alter table public.hr_sessions add column if not exists qualite jsonb;

grant select, insert, update, delete on public.protocol_test_results to authenticated;
grant select, insert, delete on public.hr_sessions to authenticated;
