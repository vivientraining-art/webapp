# Guide — Coaching individuel

Application **séparée** de tes autres outils (`moniteur-groupe-polar.html` pour tes séances
de groupe, `espace-adherent.html` pour l'auto-saisie des adhérents). Celle-ci sert à suivre
tes **clients en individuel** : c'est toi, le coach, qui l'utilises pendant ou après chaque
séance pour enregistrer sa fréquence cardiaque, et le tonnage / la 1RM estimée de ses exercices
de renforcement musculaire. Les clients n'ont pas de compte — rien à leur faire créer.

Fichiers ajoutés (aucun fichier existant n'a été modifié) :
- `coaching-individuel.html` — l'application coach.
- `supabase-migration-3-coaching-individuel.sql` — les nouvelles tables à installer une fois.
- `GUIDE-COACHING-INDIVIDUEL.md` — ce guide.

---

## Étape 1 — Installer les nouvelles tables

1. Dans Supabase (le **même projet** que ton espace adhérent) : **SQL Editor** → **New query**.
2. Ouvre `supabase-migration-3-coaching-individuel.sql`, copie tout son contenu, colle-le, **Run**.
3. Ce script ajoute trois tables (`coaching_clients`, `coaching_sessions`, `strength_sets`),
   toutes protégées par des règles RLS **réservées à ton compte coach** — un client ne peut
   jamais y accéder, il n'a même pas de compte.

> Il faut que ton compte ait déjà le rôle `coach` (voir `GUIDE-ESPACE-ADHERENT.md`, étape 6).
> Sans ça, l'app affichera « Ce compte n'est pas configuré comme coach — accès refusé ».

## Étape 2 — Ouvrir l'application

`coaching-individuel.html` est déjà configuré avec les mêmes clés Supabase publiques que ton
espace adhérent (même projet, donc rien à modifier). Ouvre le fichier, connecte-toi avec ton
e-mail/mot de passe coach habituel.

## Étape 3 — Utilisation

1. **Mes clients** : ajoute un client (nom + FC max), clique sur sa fiche pour l'ouvrir.
2. **Séance** :
   - Connecte un capteur cardiaque Bluetooth (optionnel — ceinture/montre type Polar) avant de
     démarrer si tu veux la FC moyenne/min/pic et la VFC (RMSSD) enregistrées automatiquement.
   - Clique **Démarrer la séance** : ça chronomètre et ouvre la saisie des séries. Fonctionne
     aussi sans capteur (juste le chrono).
   - Ajoute chaque exercice (charge, répétitions, séries) : le **tonnage** (charge × reps ×
     séries) et la **1RM estimée** (formule d'Epley) sont calculés et enregistrés immédiatement.
   - **Arrêter & enregistrer** clôture la séance et sauvegarde le résumé FC.
3. **Historique** : toutes les séances passées du client, avec le détail des exercices.
4. **Progression** : courbes de tonnage total par séance et de 1RM estimée par exercice.

## Publication

Héberge `coaching-individuel.html` au même endroit que tes autres apps (GitHub Pages, etc.).
C'est un outil coach uniquement — inutile de le partager avec tes clients.

## RGPD — données de santé

Comme pour l'espace adhérent, la fréquence cardiaque est une donnée de santé sensible. Le
projet Supabase est déjà hébergé en Europe (voir `GUIDE-ESPACE-ADHERENT.md`). Ici, c'est toi
qui saisis les données de tes clients en tant que coach dans le cadre du suivi sportif que tu
leur fournis — informe-les que tu conserves ces données et qu'ils peuvent t'en demander la
suppression à tout moment (bouton **Supprimer ce client** dans sa fiche, qui efface aussi tout
son historique de séances et de séries).
