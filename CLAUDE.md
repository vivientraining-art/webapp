# Suivi des tests (version association) — contexte pour Claude Code

Logiciel de suivi de tests physiques de Vivien Strudel, coach sportif, pour
ses trois cours adultes (Gironville, Milly, Boutigny). Publié sur GitHub Pages
(dépôt public, données protégées par Supabase RLS). C'est le **terrain de
tests et de recherche** ; la version commerciale est le dépôt privé
`vivientraining-art/quarbon`, qui partage cet historique.

## Règles de travail

- Répondre et écrire en **français** (code, commentaires, messages de commit,
  textes de l'interface), en tutoyant l'utilisateur final.
- L'utilisateur veut que le travail soit **fusionné sur `main` et publié** sans
  lui demander à chaque fois. Travailler sur une branche `claude/…`, fusionner
  avec `--no-ff`, pousser.
- Ne **jamais** demander de coller une clé, un mot de passe ou un `service_role`
  dans la conversation : ils vont dans les secrets de l'environnement.
- Les adhérents ont consenti à une utilisation par l'association seulement
  (RGPD) : aucune donnée ne sort vers Quarbon ou ailleurs.
- Les scripts SQL sont exécutés **à la main** par l'utilisateur dans Supabase
  (SQL Editor) : toujours fournir des scripts rejouables, avec les `grant`.
- Tester dans un navigateur (Playwright, Chromium préinstallé) avec un faux
  client Supabase en mémoire avant de publier ; vérifier les calculs à la main.

## Lien avec la version commerciale (Quarbon)

Une amélioration validée ici peut être reportée dans `quarbon` par
`git cherry-pick` (en retirant noms, cours et config propres à l'association).
Ne jamais copier de données d'adhérents vers Quarbon.

## Architecture

- Pages statiques, un fichier HTML + JS chacune, sans étape de build :
  - `espace-adherent.html` : compte adhérent, profil, protocole de test guidé
    sur téléphone avec capteur cardiaque Bluetooth (Web Bluetooth : Chrome
    Android, Bluefy sur iPhone), historique, progression ;
  - `moniteur-groupe-polar.html` : espace coach (détail par date et groupe,
    récap des groupes, inscrits, « À vérifier », lancement synchronisé de
    l'AMRAP, saisie et correction, exports Excel / CSV / anonymisé) ;
  - `politique-confidentialite.html` : politique de l'association.
- Supabase : Auth, RLS (`public.is_coach()`), Realtime broadcast `live-coach`
  (statut des téléphones, départ / STOP de l'AMRAP), RPC `coach_list_users`,
  `coach_delete_user`. Tables : `profiles`, `hr_sessions`,
  `protocol_test_results` (une ligne par participant × point de test × test,
  données en `jsonb`), `measurements` (ancien format).
- Schéma : `supabase-schema.sql` puis migrations 2 à 13 dans l'ordre.
- SheetJS (xlsx 0.18.5) chargé à la demande pour l'export Excel.

## Protocole Force + Cardio (règles métier à respecter)

Questionnaire (sommeil au quart d'heure, fatigue 1–10, malade) → échauffement →
préhension (3 essais par main, meilleur retenu, essais manquants acceptés) →
4 ateliers en rotation (pompes 3 variantes, wall-sit plafond 300 s, rowing et
RDL barre ; 1 min = plafond, max de répétitions) → AMRAP 20 min (circuit
`C1-2026-10`, 81 rép./tour, option No impact ; notation : tours + atelier
d'arrêt + répétitions sur cet atelier ; compteur « +1 tour ») → récupération
automatique 2 min → retour au calme.

- FC max retenue = max(Tanaka 208 − 0,7 × âge, pic observé fiable ≤ 220).
  Zones en % FC max : <50, 50–60, 60–70, 70–80, 80–90, ≥90.
- Récupération : FC arrêt = moyenne des 5 s avant STOP ; FC 60 s / 120 s =
  moyennes de 5 s centrées ; HRR60, HRR120.
- Mesure invalide : valeur 0, < 40 ou > 220 ; signal plat (écart-type < 2 sur
  30 s pendant l'effort) ; perte de signal > 5 s ; FC 120 s ≥ FC arrêt.
- T1+ reprend les conditions du T0 (station de départ, variante, charges, No
  impact) ; tout écart est enregistré dans `ecart_protocole`.
