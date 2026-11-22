-- SILONG database setup. Run once in Supabase: SQL Editor, New query, paste all of this, Run.
-- Safe to run again: tables are only created if missing, and policies and functions are replaced.

-- 1. Each signed-in person's app data (rentals and SILONG credit). Only they can read or change it.
create table if not exists public.user_data (
  user_id uuid not null references auth.users (id) on delete cascade,
  key text not null check (key in ('rentals', 'wallet')),
  value jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);
alter table public.user_data enable row level security;
drop policy if exists "read own data" on public.user_data;
create policy "read own data" on public.user_data for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "add own data" on public.user_data;
create policy "add own data" on public.user_data for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "change own data" on public.user_data;
create policy "change own data" on public.user_data for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "remove own data" on public.user_data;
create policy "remove own data" on public.user_data for delete to authenticated using ((select auth.uid()) = user_id);

-- 2. Messages from the support form. Anyone can send one; only the team reads them (Table Editor, tickets).
create table if not exists public.tickets (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  user_id uuid default auth.uid(),
  name text check (char_length(name) <= 120),
  email text check (char_length(email) <= 200),
  category text check (char_length(category) <= 80),
  reference text check (char_length(reference) <= 120),
  message text not null check (char_length(message) between 1 and 4000)
);
alter table public.tickets enable row level security;
drop policy if exists "send a ticket" on public.tickets;
create policy "send a ticket" on public.tickets for insert to anon, authenticated with check (user_id is null or user_id = (select auth.uid()));

-- 3. The visit counter: anonymous events. No IP addresses, no cookies, no user ids.
create table if not exists public.events (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  event text not null check (event in ('visit', 'demo_start', 'signup', 'rental_start', 'rental_return', 'ask', 'qr_scan', 'qr_link')),
  device text check (device in ('phone', 'tablet', 'desktop')),
  lang text check (lang in ('en', 'fil'))
);
alter table public.events enable row level security;
drop policy if exists "count an event" on public.events;
create policy "count an event" on public.events for insert to anon, authenticated with check (true);
-- The website can't read single events; stats.html only gets the totals below.

-- 4. Totals for stats.html (Philippine time).
create or replace function public.silong_stats()
returns json language sql stable security definer set search_path = '' as $
  with e as (select event, device, (created_at at time zone 'Asia/Manila') as local_at from public.events),
       d as (select (now() at time zone 'Asia/Manila')::date as today)
  select json_build_object(
    'totals',  (select coalesce(json_object_agg(event, c), '{}'::json) from (select event, count(*) c from e group by event) t),
    'today',   (select coalesce(json_object_agg(event, c), '{}'::json) from (select event, count(*) c from e, d where local_at::date = d.today group by event) t),
    'week',    (select coalesce(json_object_agg(event, c), '{}'::json) from (select event, count(*) c from e, d where local_at::date > d.today - 7 group by event) t),
    'devices', (select coalesce(json_object_agg(device, c), '{}'::json) from (select device, count(*) c from e where event = 'visit' and device is not null group by device) t),
    'daily',   (select coalesce(json_agg(json_build_object('day', day, 'visits', c) order by day), '[]'::json)
                from (select local_at::date as day, count(*) c from e, d where event = 'visit' and local_at::date > d.today - 14 group by 1) t)
  );
$$;
revoke all on function public.silong_stats() from public;
grant execute on function public.silong_stats() to anon, authenticated;

-- 5. Let people delete their own account from My Account. Their rentals, credit and support messages go with it.
create or replace function public.delete_my_account()
returns void language sql security definer set search_path = '' as $
  delete from public.tickets where user_id = (select auth.uid());
  delete from auth.users where id = (select auth.uid());
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
