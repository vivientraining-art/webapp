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
6. `supabase-migration-8-suppression-coach.sql` — autorise le compte coach à
   supprimer des tests depuis l'espace coach.
7. `supabase-migration-9-reparation-inscription.sql` — rattrape une migration
   oubliée (colonnes nom, cours, date de naissance…) et rend la création de
   compte robuste : elle ne peut plus échouer avec « Erreur base de données à
   la création ». Sans risque, peut être relancée.
8. `supabase-migration-10-modification-coach.sql` — autorise le compte coach à
   corriger les résultats et les profils des adhérents.

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
   (l'onglet Capteur a été retiré : le capteur se connecte uniquement
   depuis le protocole), sans action supplémentaire.
   Choisir aussi l'**atelier de départ** (Préhension, Pompes, Wall-sit, Rowing
   ou RDL), indiqué par le coach : les ateliers de force se passent **en
   rotation**, plusieurs participants par atelier. L'app enchaîne ensuite les
   5 ateliers dans l'ordre du circuit en boucle (ex. départ Rowing → Rowing,
   RDL, Préhension, Pompes, Wall-sit), avec 75 s de repos pour tourner entre
   deux ateliers et un repos long (4 min) après le 5e. Tout le groupe se
   retrouve ensuite pour l'AMRAP, la RFC et le retour au calme. La position de
   chaque atelier dans la rotation est enregistrée (colonne `atelier_depart`
   de l'export).
3. **Commencer le protocole** : l'app guide dans l'ordre prévu (échauffement,
   préhension, pompes, wall-sit, rowing, RDL, repos, AMRAP cardio, récupération
   FC, retour au calme), avec minuteurs de repos intégrés (60–90 s, puis
   3–5 min avant le cardio) et chrono de **20 min** pour l'AMRAP.
   - Circuit de l'AMRAP, en boucle : 20 jumping jacks, 10 squats, 10 skatings,
     5 sprawls, 1 burpee, 5 pompes, 5 supermans, 20 mountain climbers,
     5 squat jumps.
   - Case **No impact** : pour ceux qui ne peuvent pas sauter, les jumping
     jacks deviennent des step jacks, les squat jumps des squats et le burpee
     se fait sans saut. Le choix est enregistré avec le résultat (colonne
     `amrap_no_impact`), ainsi que la durée (`amrap_duree_min` : 20 ; vide
     pour les anciens AMRAP de 10 min, à ne pas comparer directement).
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
   Pendant le test, deux boutons restent disponibles en haut :
   - **Reconnecter le capteur** : si le capteur décroche (l'état passe en
     rouge « Capteur déconnecté »), un toucher le reconnecte sans quitter le
     test ; si ça échoue, un second toucher rouvre la liste Bluetooth. Pendant
     la coupure, aucune FC n'est comptée (pas de valeur figée dans la moyenne).
   - **Arrêter le test** : interrompt la passation (avec confirmation). Les
     étapes déjà validées restent enregistrées, ainsi que la FC déjà mesurée.
5. **Refaire un test** : une fois le protocole terminé, « Commencer le
   protocole » repart de la première étape. Si des résultats existent déjà pour
   ce point de test, l'app demande confirmation : les nouveaux résultats
   remplacent les anciens de ce point au fur et à mesure. Pour garder les deux,
   choisir le point de test suivant (T1, T2…).
6. L'onglet **Mon historique** affiche ensuite ses résultats bruts,
   test par test, colonne par point de test (T0 à T3) — aucun score calculé.
   Chaque élément peut y être **supprimé par l'adhérent** en cas d'erreur
   (✕ à côté d'une séance capteur, d'une mesure ou d'un résultat, ou bouton
   « Supprimer le test T0 » pour toute une passation), avec confirmation.

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
- le **temps passé dans chaque zone d'effort** (repos < 50 %, Z1 50–60 %,
  Z2 60–70 %, Z3 70–80 %, Z4 80–90 %, Z5 ≥ 90 % de la FC max de Tanaka) est
  affiché sous les séances capteur de chaque adhérent, avec une barre colorée ;
- **Modifier / supprimer** active le mode correction : un crayon ✎ apparaît
  à côté du nom de chaque adhérent (nom, prénom, cours, genre, date de
  naissance) et de chaque test (valeurs, point de test, date), et une croix ✕
  pour supprimer. Les autres valeurs du test sont conservées ; la RFC est
  recalculée si on corrige une FC, la FC max si on corrige la date de
  naissance. « Terminer les corrections » masque les boutons.

Chaque adhérent doit renseigner **nom, prénom, cours, genre et date de naissance** (obligatoire à
l'inscription ; les comptes existants le saisissent à leur prochaine
connexion). Nécessite `supabase-migration-6-nom-cours.sql`. Un adhérent sans
cours apparaît dans le groupe « Sans cours ».

Le fichier CSV contient une ligne par adhérent, par date et par point de test,
avec date, cours, nom, prénom, genre, âge, FC max de Tanaka, résumé FC du jour,
temps en secondes dans chaque zone (temps_repos_s, temps_z1_s … temps_z5_s), puis une colonne par valeur
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
