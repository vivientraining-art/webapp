# Guide — Protocole de test Force + Cardio (espace adhérent)

Le protocole "Force + Cardio" est intégré directement dans `espace-adherent.html`,
onglet **Protocole test**. Chaque adhérent le passe lui-même, sur son propre
compte — plus besoin d'un outil séparé pour le coach.

Les tests cognitifs (Go/No-Go, Stroop, N-back) ont été retirés de l'app.

## Installation

Exécuter dans Supabase (SQL Editor → New query → Run), **dans l'ordre**, si ce
n'est pas déjà fait :
1. `supabase-migration-3-protocole-force-cardio.sql` — crée la table.
2. `supabase-migration-4-protocole-adherent.sql` — adapte les droits pour que
   chaque adhérent gère ses propres résultats (le protocole n'étant plus
   administré par le coach mais auto-saisi).
3. `supabase-migration-5-rfc-amrap.sql` — autorise le nouveau type de test
   "rfc" (récupération de la fréquence cardiaque après l'AMRAP).
4. `supabase-migration-6-nom-cours.sql` — ajoute le nom et le cours
   (Gironville, Milly, Boutigny) au profil de chaque adhérent.
5. `supabase-migration-7-genre-age-tanaka.sql` — ajoute le genre et la date de
   naissance ; la FC max est calculée avec la formule de Tanaka.

## FC max : formule de Tanaka

La FC max de chaque adhérent n'est plus saisie à la main : elle est calculée
automatiquement à partir de son âge, **FC max = 208 − 0,7 × âge**, et
recalculée à chaque connexion (elle suit les anniversaires). La formule et sa
source sont affichées dans l'onglet « Mon profil » :

> Tanaka H., Monahan K.D., Seals D.R. (2001). « Age-predicted maximal heart
> rate revisited ». *Journal of the American College of Cardiology*, 37(1),
> 153-156. doi:10.1016/S0735-1097(00)01054-8

## Côté adhérent

Onglet **Protocole test** :
1. Choisir le point de test (T0/T1/T2/T3, indiqué par le coach).
2. Facultatif : connecter son capteur cardiaque — la fréquence cardiaque est
   alors enregistrée automatiquement pendant toute la durée du protocole
   (même mécanisme que l'onglet Capteur), sans action supplémentaire.
3. **Commencer le protocole** : l'app guide dans l'ordre prévu (échauffement,
   préhension, pompes, wall-sit, rowing, RDL, repos, AMRAP cardio, récupération
   FC, retour au calme), avec minuteurs de repos intégrés (60–90 s, puis
   3–5 min avant le cardio) et chrono de 10 min pour l'AMRAP.
   - Si un capteur est connecté, la FC pic et la FC moyenne pendant l'AMRAP
     sont enregistrées automatiquement avec le résultat du test.
   - Juste après l'AMRAP, un chrono de **2 minutes de récupération** démarre
     automatiquement : la FC relevée à la fin de ces 2 minutes, comparée à la
     FC de fin d'effort, donne la **RFC** (récupération de la fréquence
     cardiaque). Sans capteur connecté, cette étape peut être passée.
4. Chaque étape est enregistrée dès qu'on clique sur "Enregistrer et
   continuer" — **même en cas de rechargement de la page ou de fermeture de
   l'app, rien n'est perdu** : au retour, le protocole reprend automatiquement
   à l'étape exacte où l'adhérent s'était arrêté (le point de test choisi est
   mémorisé sur l'appareil, et chaque étape déjà validée est déjà en base).
5. L'onglet **Mon historique** affiche ensuite ses résultats bruts,
   test par test, colonne par point de test (T0 à T3) — aucun score calculé.

## Côté coach

Tout se passe dans l'**espace coach** (`moniteur-groupe-polar.html`), qui n'a
plus qu'un seul écran :
- filtre **Cours** (Tous / Gironville / Milly / Boutigny) et filtre **Date** ;
- les données sont affichées **par date, puis par cours**, une ligne par
  adhérent (séances capteur, résultats du protocole, autres mesures) ;
- le bloc **En direct** montre la FC des adhérents en séance (filtré lui aussi
  par cours) ; les données se rechargent automatiquement quand un adhérent
  enregistre quelque chose, ou via **Rafraîchir** ;
- **Exporter la sélection (CSV)** télécharge exactement ce qui est filtré.

Chaque adhérent doit renseigner **nom, prénom, cours, genre et date de naissance** (obligatoire à
l'inscription ; les comptes existants le saisissent à leur prochaine
connexion). Nécessite `supabase-migration-6-nom-cours.sql`. Un adhérent sans
cours apparaît dans le groupe « Sans cours ».

Le fichier CSV contient une ligne par adhérent, par date et par point de test,
avec date, cours, nom, prénom, genre, âge, FC max de Tanaka, résumé FC du jour, puis une colonne par valeur
brute : préhension, pompes, wall-sit, rowing, RDL, AMRAP (tours, station, FC
moyenne/pic) et RFC. Aucun score n'est calculé. Séparateur
point-virgule et décimales à virgule : il s'ouvre directement dans Excel en
français. Sur iPad, la feuille de partage propose « Enregistrer dans
Fichiers ».

## Limite à connaître

Si l'adhérent recharge la page **en plein milieu** d'une connexion Bluetooth
active, la connexion au capteur est coupée (limitation du Bluetooth web, pas
de l'app) : il faudra la refaire. Les résultats des tests déjà validés, eux,
ne sont jamais perdus.
