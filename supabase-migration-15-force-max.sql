-- =====================================================================
--  Migration 15 — Tests de force max (5RM) pour l'hexagone des objectifs
--  À exécuter dans Supabase → SQL Editor → New query → Run
--
--  Autorise le type de résultat « force_max » : squat, développé couché et
--  RDL en 5RM (1RM estimé), tractions (maximum de répétitions).
--  Sans risque, peut être relancée.
-- =====================================================================

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
  check (test_type in ('grip', 'pompes', 'wallsit', 'rowing', 'rdl', 'amrap_cardio', 'rfc', 'questionnaire', 'force_max'));

grant select, insert, update, delete on public.protocol_test_results to authenticated;

-- Vérification : doit afficher la nouvelle règle avec « force_max »
select pg_get_constraintdef(oid) from pg_constraint where conname = 'protocol_test_results_test_type_check';
