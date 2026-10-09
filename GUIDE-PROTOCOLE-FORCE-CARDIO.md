# Guide — Protocole de test Force + Cardio

Le protocole « Force + Cardio » se passe dans l'**espace adhérent**
(`espace-adherent.html`, onglet **Protocole test**) : chaque adhérent le passe
sur son téléphone, avec son capteur cardiaque. Le coach suit, pilote et
exporte tout depuis l'**espace coach** (`moniteur-groupe-polar.html`).

## Installation (Supabase)

Exécuter dans Supabase (SQL Editor → New query → Run), **dans l'ordre**, si ce
n'est pas déjà fait :
1. `supabase-migration-3-protocole-force-cardio.sql` — crée la table des résultats.
2. `supabase-migration-4-protocole-adherent.sql` — chaque adhérent gère ses propres résultats.
3. `supabase-migration-5-rfc-amrap.sql` — type de test « récupération ».
4. `supabase-migration-6-nom-cours.sql` — nom et cours (Gironville, Milly, Boutigny).
5. `supabase-migration-7-genre-age-tanaka.sql` — genre, date de naissance, FC max.
6. `supabase-migration-8-suppression-coach.sql` — le coach peut supprimer des tests.
7. `supabase-migration-9-reparation-inscription.sql` — création de compte robuste (rejouable sans risque).
8. `supabase-migration-10-modification-coach.sql` — le coach peut corriger résultats et profils.
9. `supabase-migration-11-comptes-inscrits.sql` — vue « Inscrits » complète.
10. `supabase-migration-12-saisie-suppression-coach.sql` — saisie de résultats et suppression de doublons par le coach.
11. `supabase-migration-13-questionnaire-qualite.sql` — questionnaire avant test et qualité du signal des séances.

## Déroulé d'une passation (côté adhérent)

À l'accueil de l'onglet **Protocole test**, l'adhérent choisit le **point de
test** (T0, T1, T2…) et sa **station de départ**, connecte son capteur, puis
touche « Commencer le protocole ». Chaque résultat est rattaché au point de
test choisi. L'app enchaîne :

1. **Questionnaire** (30 s) : heures de sommeil la nuit précédente (au quart
   d'heure près), fatigue de 1 (pas du tout) à 10 (épuisé), malade ou non. La
   date et l'heure de la séance sont enregistrées automatiquement.
2. **Échauffement** 8–10 min (non noté).
3. **Force de préhension** pour tout le monde : 3 essais par main en alternant
   droite → gauche, 15 s entre deux prises. Les 3 essais sont enregistrés et le
   **meilleur est retenu automatiquement**. Main dominante notée. Puis 60 s de repos.
   Un essai oublié ne bloque pas : l'app demande confirmation, retient le
   meilleur des essais notés et le coach voit combien il y en a (ex. « essais :
   G 2/3, D 3/3 »). Sans aucun essai, le test peut être passé ; le coach le
   complétera (vue « À vérifier »).
4. **4 ateliers en rotation** (pompes, wall-sit, rowing barre, RDL barre),
   plusieurs participants par atelier, à partir de la station de départ ; 75 s
   pour tourner entre deux ateliers, 4 min de repos après le dernier.
   - Pompes, rowing, RDL : chrono d'1 minute, **le maximum de répétitions sans
     pause, jusqu'à l'échec** (la minute est un plafond, pas un temps à tenir).
     Pompes : 3 variantes (genoux sans gainage, genoux avec gainage, jambes
     tendues). Rowing et RDL : charge totale barre + disques.
   - Wall-sit : chrono intégré, arrêt au premier décroché ou au **plafond de
     300 s**, case « plafond atteint » cochée automatiquement.
5. **AMRAP cardio 20 min** : 20 jumping jacks, 10 squats, 10 skatings,
   5 sprawls, 1 burpee, 5 pompes, 5 supermans, 20 mountain climbers,
   5 squat jumps (81 répétitions par tour). Option **No impact** : step jacks,
   squats et burpee sans saut. Le chrono démarre tout seul si le coach donne le
   départ depuis son espace ; sinon l'adhérent touche « Démarrer les 20 min » au
   top départ. Au STOP, l'adhérent note les **tours complets**
   et les **répétitions du tour incomplet** ; l'app calcule les **répétitions
   totales** et enregistre la **version du circuit** (`C1-2026-10`) et son contenu.
   Effort ressenti (0 à 10).
6. **Récupération cardiaque — automatique** : dès le STOP (fin du chrono, STOP
   du coach ou bouton « Fin de l'AMRAP »), un compte à rebours de 2 min
   s'affiche avec la consigne **« Assis, immobile, sans parler »**. L'app
   mesure, sans aucune saisie :
   - **FC à l'arrêt** : moyenne des 5 dernières secondes avant le STOP ;
   - **FC à 60 s** et **FC à 120 s** : moyenne sur 5 s centrées sur chaque instant ;
   - **HRR60** = FC arrêt − FC 60 s et **HRR120** = FC arrêt − FC 120 s.

   La FC pic de l'AMRAP reste une valeur à part (ce n'est pas la FC à l'arrêt).
   L'adhérent note ses tours après le bip des 2 minutes ; la récupération est
   enregistrée en même temps.
7. **Retour au calme**, fin de la séance.

Tout est enregistré au fur et à mesure : un rechargement de page ou une mise en
veille du téléphone ne fait rien perdre, et les chronos (AMRAP, récupération)
continuent sur l'heure réelle. Boutons « Reconnecter le capteur » et « Arrêter
le test » disponibles pendant toute la passation.

**Retour en arrière** : en haut de chaque étape (et pendant les repos), le
bouton « ← Corriger : … » rouvre l'étape précédente avec les valeurs déjà
notées ; on peut remonter plusieurs étapes. « Enregistrer la correction »
ramène là où on en était (un repos en cours continue de se décompter),
« Annuler la correction » aussi, sans rien changer. Pas de retour pendant un
chrono (minute, wall-sit, AMRAP, récupération). Seules les valeurs notées par
l'adhérent se corrigent : la FC de l'AMRAP et la récupération, mesurées par le
capteur, ne changent pas, et l'heure de la séance reste celle du départ. Une
fois le protocole terminé, c'est le coach qui corrige (✎ dans « Modifier /
supprimer »).

### Comparer T0 et T1 : mêmes conditions

Au T1 (et suivants), l'app **reprend automatiquement** les conditions du T0 :
station de départ, variante de pompes, charges du rowing et du RDL, option No
impact, main dominante. Si l'adhérent en change une, un avertissement s'affiche
— « Attention, différent du T0 : la comparaison ne sera pas valide » — et
l'écart est enregistré dans la colonne **« écart au protocole »**.

À annoncer aux adhérents : même jour et même heure à chaque test, pas de séance
intense dans les 48 h avant, mêmes habitudes (repas, café, sommeil). Faire
remplir le Q-AAP (questionnaire de santé) avant le T0.

## Fréquence cardiaque : calculs et qualité du signal

- **FC max retenue** = la plus haute entre la formule de Tanaka
  (208 − 0,7 × âge) et le **pic de FC réellement observé** chez la personne
  (séances au signal fiable). Elle sert aux zones d'effort (repos < 50 %,
  Z1 50–60 %, Z2 60–70 %, Z3 70–80 %, Z4 80–90 %, Z5 ≥ 90 %) et à
  l'**intensité de l'AMRAP** (FC moyenne en % de la FC max retenue). La source
  utilisée (Tanaka ou pic observé) est indiquée partout.
  > Tanaka H., Monahan K.D., Seals D.R. (2001). « Age-predicted maximal heart
  > rate revisited ». *J Am Coll Cardiol*, 37(1), 153-156. doi:10.1016/S0735-1097(00)01054-8
- La **RMSSD n'est plus calculée** (elle n'a pas de sens pendant l'effort).
- **Mesure invalide** si : FC = 0, < 40 ou > 220 bpm ; signal plat (écart-type
  < 2 bpm sur 30 s pendant l'effort) ; perte de signal de plus de 5 s pendant
  la fenêtre de mesure ; FC à 120 s ≥ FC à l'arrêt. La mesure est conservée
  mais marquée invalide, avec le motif, et exclue des moyennes du récap.
- **% de données valides** calculé pour chaque séance.
- Indicateur de signal pendant la passation : **vert** (connecté, signal
  correct), **orange** (signal douteux : humidifier et resserrer la ceinture),
  **rouge** (déconnecté).
- Le **nom du capteur** (ex. « Polar H10 8A2B3C4D », identifiant imprimé au dos)
  s'affiche sous la FC pour que chacun vérifie que c'est bien le sien.

## Côté coach

### Lancer l'AMRAP (vérification des capteurs)

Ce n'est pas obligatoire : chaque adhérent peut aussi toucher « Démarrer les
20 min » au top départ, ou « Fin de l'AMRAP → lancer la récup » au STOP. Mais
pour un groupe qui part ensemble, l'onglet **Lancer l'AMRAP** est le plus fiable
(même départ pour tous, capteurs vérifiés, STOP et récupération synchronisés) :
- tous les téléphones en protocole s'affichent, **quel que soit le cours
  d'inscription** : un adhérent qui passe son test pendant un autre cours que
  le sien part avec le groupe présent (ses résultats restent rattachés à son
  propre cours). Le filtre de cours n'a pas d'effet sur cet onglet ;
- **Prêts pour l'AMRAP** : ceux qui ont terminé leurs ateliers de force, cochés
  par défaut ; décocher quelqu'un qui ne part pas avec ce groupe ;
- **Autres téléphones** : ceux qui sont encore aux ateliers, par exemple le
  2e groupe quand on tourne en deux groupes avec les mêmes capteurs. Ils ne
  reçoivent ni le départ ni le STOP, et leur capteur rouge ne bloque rien ;
- **Démarrer le chrono (20 min)** n'est possible que si **tous les capteurs
  cochés sont au vert** ; **Forcer le démarrage** permet de lancer quand même ;
- le départ est donné au même moment sur les téléphones cochés, et seulement
  sur eux ; à 20:00 (ou avec le bouton **STOP**), la récupération de 2 min
  démarre sur ces téléphones. Un téléphone qui a raté le départ ou le STOP
  (connexion coupée) le reçoit à nouveau quelques secondes plus tard, recalé
  sur l'heure réelle ;
- **Nouveau groupe** prépare le départ suivant. Recharger la page ne fait pas
  perdre le groupe en cours.

La FC en direct affiche aussi tous les téléphones en protocole, quel que soit
le filtre de cours.

### Autres vues

- **Détail** : par date puis par cours d'inscription (un adhérent venu à un
  autre cours apparaît sous le sien), une ligne par adhérent (séances
  capteur avec % de données valides et temps par zone, résultats du protocole,
  questionnaire, ⚠ en cas d'écart au protocole), FC max retenue et sa source.
- **Récap des groupes** : « Tous les groupes » puis chaque cours — moyennes par
  point de test, min–max, effectif, évolution appariée (seulement les
  adhérents présents aux deux points). Profil du groupe (femmes / hommes, âge),
  sommeil, fatigue, malades, écarts au protocole. Répétitions totales de
  l'AMRAP (estimées pour l'ancien format : tours × 81 + stations terminées),
  intensité, HRR60 / HRR120 (mesures invalides exclues). L'ancien calcul de la
  RFC (pic − FC à 2 min) reste affiché à part : il n'est pas comparable aux HRR.
- **Inscrits** : tous les comptes, même sans résultat ; doublons possibles,
  profils incomplets, e-mails non confirmés.
- **À vérifier** (badge rouge, alerte et notification à la connexion) :
  valeurs anormales ou mesures invalides, résultats incomplets, comptes à
  vérifier, inscrits sans résultat. « Corriger » / « Compléter » ouvrent la
  saisie ; « C'est correct » / « Masquer » retirent une alerte (sur cet appareil).
- **+ Saisir des résultats** : tout le protocole d'un point de test sur un seul
  formulaire, pour n'importe quel adhérent (venu sans téléphone, valeur
  oubliée) ; meilleur essai, répétitions totales, HRR et validité calculés.
- **Modifier / supprimer** : ✎ pour corriger un test ou un profil, ✕ pour
  supprimer un test ou un compte (doublon).
- Filtres **cours**, **genre** et **date** ; exports **Excel (.xlsx)**
  multi-onglets (Résultats, Récap groupes, Inscrits, À vérifier, Infos) et
  **CSV**. Chaque ligne de résultats contient toutes les valeurs brutes, dont
  les 3 essais de préhension, les répétitions de l'AMRAP, l'intensité, la FC à
  l'arrêt / 60 s / 120 s, HRR60 / HRR120, la validité et ses motifs, le
  questionnaire et l'écart au protocole.
- **Export anonymisé** (Excel, ou CSV si Excel est indisponible) : mêmes
  résultats sans nom, prénom, e-mail ni date de naissance (l'âge reste). Chaque
  personne a un **id_participant** (ex. P07T47MV), toujours le même d'un export
  à l'autre pour suivre T0 → T1, et chaque cours un **id_groupe** (G1 Gironville,
  G2 Milly, G3 Boutigny, G0 sans cours). La correspondance n'existe que dans
  l'export Excel normal (colonnes id_participant et id_groupe). Ce sont des
  données pseudonymisées : à partager seulement avec des personnes de confiance.

## Limite à connaître

Si l'adhérent recharge la page **en plein milieu** d'une connexion Bluetooth,
la connexion au capteur est coupée (limitation du Bluetooth web) : il faut la
refaire avec « Reconnecter le capteur ». Les résultats déjà validés et
l'historique de FC de la séance, eux, ne sont jamais perdus.
