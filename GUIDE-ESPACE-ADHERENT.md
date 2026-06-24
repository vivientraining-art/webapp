# Guide — Espace adhérent (Supabase)

Cet espace permet à **chaque adhérent de se connecter et d'enregistrer lui-même ses
statistiques** (force, préhension, VO2max, et séances de fréquence cardiaque via son
propre capteur Polar H10). Toi, en tant que **coach**, tu vois les données de tout le monde.

Fichiers :
- `espace-adherent.html` — l'application adhérent (+ vue coach intégrée)
- `supabase-schema.sql` — la base de données à installer une fois
- `moniteur-groupe-polar.html` — ton app coach existante (inchangée)

---

## Étape 1 — Créer le projet Supabase ✅ (déjà fait)

Tu as déjà créé ton compte. Si le projet n'existe pas encore :
1. Va sur https://supabase.com → **New project**.
2. Donne un nom (ex. `vivien-adherents`), choisis une région **Europe** (ex. *EU West / Paris*)
   — important pour le RGPD car on stocke des données de santé.
3. Note bien le **mot de passe de base de données** (tu n'en auras pas besoin pour l'app).

## Étape 2 — Installer la base de données

1. Dans Supabase : menu de gauche → **SQL Editor** → **New query**.
2. Ouvre `supabase-schema.sql`, copie **tout** son contenu, colle-le, puis clique **Run**.
3. Tu dois voir « Success. No rows returned ». ✔

## Étape 3 — Récupérer tes clés

1. Menu de gauche → **Project Settings** (la roue dentée) → **API**.
2. Copie deux valeurs :
   - **Project URL** → ressemble à `https://abcd1234.supabase.co`
   - **Project API keys → `anon` `public`** → une longue chaîne `eyJ...`

> La clé `anon` est **publique** : elle peut figurer dans le fichier HTML sans danger.
> La sécurité est assurée par le *Row Level Security* installé à l'étape 2.
> ⚠️ Ne mets **jamais** la clé `service_role` dans le fichier.

## Étape 4 — Renseigner l'application

Ouvre `espace-adherent.html`, en haut du `<script>` remplace :

```js
const SUPABASE_URL      = 'https://VOTRE-PROJET.supabase.co';
const SUPABASE_ANON_KEY = 'VOTRE_CLE_ANON_PUBLIQUE';
```

par tes vraies valeurs.

> 👉 Donne-moi simplement ces deux valeurs et je les insère pour toi.

## Étape 5 — Régler la connexion par e-mail

1. Supabase → **Authentication** → **Providers** → vérifie que **Email** est activé.
2. **Authentication** → **URL Configuration** → ajoute l'URL où le fichier sera publié
   dans **Site URL** et **Redirect URLs** (ex. `https://vivientraining-art.github.io/...`).
   Pour tester en local, ajoute aussi `http://localhost`.
3. (Recommandé) **Authentication → Providers → Email** : laisse « Confirm email » activé.
   Les adhérents recevront un **lien magique** — pas de mot de passe à gérer.

## Étape 6 — Te désigner comme coach

1. Connecte-toi **une première fois** dans `espace-adherent.html` avec ton e-mail
   (clique le lien magique reçu). Cela crée ton profil.
2. Retourne dans Supabase → **SQL Editor** et lance (avec ton e-mail) :

```sql
update public.profiles set role = 'coach'
where email = 'ton-email@exemple.fr';
```

3. Recharge l'app : l'onglet **Vue coach** apparaît, avec tous les adhérents.

## Étape 7 — Publier

Héberge `espace-adherent.html` au même endroit que ton app coach (GitHub Pages, etc.)
et partage le lien à tes adhérents. Ils se connectent avec leur e-mail, c'est tout.

---

## RGPD — données de santé (important)

Tu stockes de la **FC, VO2max, etc.** = données de santé (catégorie sensible).
À prévoir avant d'ouvrir aux adhérents :
- **Hébergement en Europe** (région Supabase EU — étape 1).
- **Consentement explicite** des adhérents (une mention + case à cocher à l'inscription).
- **Information** : finalité (suivi sportif), durée de conservation, droit d'accès/suppression.
- Un adhérent peut déjà **supprimer ses propres mesures** (prévu côté base) ;
  on peut ajouter un bouton « supprimer mon compte » si tu le souhaites.

Je peux ajouter l'écran de consentement et le bouton de suppression quand tu veux.

---

## Ce qu'on peut ajouter ensuite
- Graphiques de progression (1RM, VO2max dans le temps).
- Export CSV côté adhérent et côté coach.
- Tests cognitifs (réactivité, Stroop, N-back) repris de l'app coach.
- Rattacher automatiquement les séances enregistrées sur **ta** tablette au compte de l'adhérent.
