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

## Côté adhérent

Onglet **Protocole test** :
1. Choisir le point de test (T0/T1/T2/T3, indiqué par le coach).
2. Facultatif : connecter son capteur cardiaque — la fréquence cardiaque est
   alors enregistrée automatiquement pendant toute la durée du protocole
   (même mécanisme que l'onglet Capteur), sans action supplémentaire.
3. **Commencer le protocole** : l'app guide dans l'ordre prévu (échauffement,
   préhension, pompes, wall-sit, rowing, RDL, repos, AMRAP cardio, retour au
   calme), avec minuteurs de repos intégrés (60–90 s, puis 3–5 min avant le
   cardio) et chrono de 10 min pour l'AMRAP.
4. Chaque étape est enregistrée dès qu'on clique sur "Enregistrer et
   continuer" — **même en cas de rechargement de la page ou de fermeture de
   l'app, rien n'est perdu** : au retour, le protocole reprend automatiquement
   à l'étape exacte où l'adhérent s'était arrêté (le point de test choisi est
   mémorisé sur l'appareil, et chaque étape déjà validée est déjà en base).
5. L'onglet **Mon historique** affiche ensuite ses résultats bruts,
   test par test, colonne par point de test (T0 à T3) — aucun score calculé.

## Côté coach

L'onglet **Vue coach** (dans le même espace adhérent) indique, pour chaque
adhérent, les points de test déjà complétés (ex. "Protocole : T0, T1"). Pour
le détail complet d'un adhérent, va dans son propre onglet Historique (ou
interroge directement la table `protocol_test_results` dans Supabase si tu
veux exporter/analyser plus finement).

## Limite à connaître

Si l'adhérent recharge la page **en plein milieu** d'une connexion Bluetooth
active, la connexion au capteur est coupée (limitation du Bluetooth web, pas
de l'app) : il faudra la refaire. Les résultats des tests déjà validés, eux,
ne sont jamais perdus.
