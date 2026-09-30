-- =====================================================================
--  Migration 5 — FC pendant l'AMRAP + récupération cardiaque (RFC)
--  À exécuter dans Supabase → SQL Editor → New query → Run
--  (après les migrations 3 et 4).
--
--  Ajoute le type de test "rfc" (récupération de la fréquence
--  cardiaque, mesurée 2 min après l'AMRAP). La FC pic/moyenne
--  pendant l'AMRAP est stockée directement dans les données du test
--  "amrap_cardio" existant (colonne jsonb "data", pas de changement
--  de structure nécessaire pour ça).
-- =====================================================================

-- Élargit la contrainte sur test_type pour autoriser 'rfc', quel que
-- soit le nom exact donné à la contrainte existante.
do $$
declare
  cname text;
begin
  select con.conname into cname
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_attribute att on att.attrelid = rel.oid and att.attnum = any(con.conkey)
  where rel.relname = 'protocol_test_results'
    and con.contype = 'c'
    and att.attname = 'test_type';
  if cname is not null then
    execute format('alter table public.protocol_test_results drop constraint %I', cname);
  end if;
end $$;

alter table public.protocol_test_results add constraint protocol_test_results_test_type_check
  check (test_type in ('grip', 'pompes', 'wallsit', 'rowing', 'rdl', 'amrap_cardio', 'rfc'));

-- Aucun nouveau droit à accorder : les permissions et règles RLS déjà
-- en place (migrations 3 et 4) couvrent ce nouveau type de test.
