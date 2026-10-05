-- =====================================================================
--  Migration 11 — Voir tous les comptes inscrits depuis l'espace coach
--  À exécuter dans Supabase → SQL Editor → New query → Run
--
--  1. Crée le profil manquant de tout compte qui n'en a pas (ex. compte
--     créé pendant que le script d'inscription était en erreur) : sans
--     profil, l'adhérent est invisible dans l'espace coach.
--  2. Ajoute une fonction réservée au coach qui liste tous les comptes
--     (même sans profil), avec la confirmation de l'e-mail et la dernière
--     connexion, pour la vue « Inscrits ».
--  Sans risque, peut être relancée.
-- =====================================================================

insert into public.profiles (id, email, prenom)
select u.id, u.email, split_part(u.email, '@', 1)
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

create or replace function public.coach_list_users()
returns table (id uuid, email text, created_at timestamptz, email_confirmed_at timestamptz, last_sign_in_at timestamptz)
language plpgsql
stable
security definer set search_path = public
as $$
begin
  if not public.is_coach() then
    raise exception 'réservé au coach';
  end if;
  return query
    select u.id, u.email::text, u.created_at, u.email_confirmed_at, u.last_sign_in_at
    from auth.users u
    order by u.created_at desc;
end;
$$;

revoke all on function public.coach_list_users() from public, anon;
grant execute on function public.coach_list_users() to authenticated;

-- Vérification : tous les comptes, avec leur profil
select u.email,
       u.created_at::date              as inscrit_le,
       u.email_confirmed_at is not null as email_confirme,
       p.nom, p.prenom, p.cours
from auth.users u
left join public.profiles p on p.id = u.id
order by u.created_at desc;
