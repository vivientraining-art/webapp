# Guide — Protocole de test Force + Cardio

Nouvel outil, séparé de tes autres apps, pour faire passer le protocole de test
"Force + Cardio" à tes adhérents (préhension, pompes, wall-sit, rowing, RDL,
AMRAP cardio). C'est toi (coach) qui pilotes l'écran pendant la séance — les
adhérents n'ont rien à installer ni à saisir eux-mêmes.

Le test Ruffier existant n'est pas concerné et reste séparé.

Fichiers :
- `protocole-force-cardio.html` — l'application.
- `supabase-migration-3-protocole-force-cardio.sql` — la table à installer une fois.

---

## Installation

1. Supabase → **SQL Editor** → colle et exécute `supabase-migration-3-protocole-force-cardio.sql`.
2. Ouvre `protocole-force-cardio.html`, connecte-toi avec ton compte coach habituel
   (même projet Supabase que tes autres apps).

## Utilisation le jour du test

1. Onglet **Nouveau test** : choisis le participant (liste de tes adhérents existants)
   et le **point de test** (T0/T1/T2/T3 — reste sélectionné d'un participant à l'autre).
2. **Commencer le protocole** : l'app te fait passer les étapes dans l'ordre prévu.
   - Échauffement et retour au calme : simples rappels, non enregistrés.
   - Chaque test affiche son protocole à lire/appliquer, les champs à remplir, puis
     un bouton pour enregistrer et passer à l'étape suivante.
   - Après pompes / wall-sit / rowing : minuteur de repos (60–90 s, ajustable).
   - Après le RDL : minuteur de repos long (3–5 min) avant le cardio.
   - AMRAP Cardio : bouton pour démarrer les 10 minutes, puis saisie du nombre de
     tours complets et de la dernière station atteinte.
3. Une fois un participant terminé, l'app revient à l'écran de sélection pour
   enchaîner avec le suivant, en gardant le même point de test.

## Historique

Onglet **Historique** → choisis un participant → tableau de ses résultats bruts,
test par test, colonne par point de test (T0 à T3). Aucun score calculé ni
normalisé, uniquement les valeurs telles que saisies — à toi de les interpréter.

## Corriger une saisie

Ré-ouvrir le protocole pour le même participant et le même point de test
pré-remplit chaque étape avec la dernière valeur enregistrée ; ré-enregistrer
remplace la valeur précédente (pas de doublon).
