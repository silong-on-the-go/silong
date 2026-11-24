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
-- The short reference shown to the person who sent it (for example SLG-4K2P9Q), so the team can find it.
alter table public.tickets add column if not exists ticket text check (char_length(ticket) <= 24);

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
returns json language sql stable security definer set search_path = '' as $$
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
returns void language sql security definer set search_path = '' as $$
  delete from public.tickets where user_id = (select auth.uid());
  delete from auth.users where id = (select auth.uid());
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- 6. For the team: everyone with an account, and whether they want launch news. The website can't
--    reach this (the "team" schema isn't published through the API). Read it in the Supabase
--    dashboard: Table Editor, schema "team", or SQL Editor: select * from team.launch_list;
create schema if not exists team;
revoke all on schema team from public, anon, authenticated;
create or replace view team.launch_list as
  select u.email,
         u.raw_user_meta_data ->> 'name' as name,
         nullif(u.raw_user_meta_data ->> 'mobile', '') as mobile,
         coalesce((u.raw_user_meta_data ->> 'launch_updates')::boolean, true) as wants_launch_news,
         u.created_at as signed_up
  from auth.users u
  where not coalesce(u.is_anonymous, false)
  order by u.created_at;
revoke all on team.launch_list from public, anon, authenticated;

-- 7. SILONG credit. People top up by bank or e-wallet transfer to the InstaPay QR and send the reference
--    number; the team checks its bank history and approves. Only approvals add credit: nobody can write to
--    the ledger directly. Payment records stay (without the account) if someone deletes their account.
create table if not exists team.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  added_at timestamptz not null default now()
);
revoke all on team.admins from public, anon, authenticated;
-- Make someone an approver (SQL Editor):
--   insert into team.admins (user_id) select id from auth.users where email = 'name@example.com';

create table if not exists public.topups (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  user_id uuid default auth.uid() references auth.users (id) on delete set null,
  code text not null unique check (code ~ '^SLG-[A-Z0-9]{6}$'),
  amount integer not null check (amount between 50 and 5000),
  bank_ref text not null check (char_length(bank_ref) between 4 and 40),
  payer_name text check (char_length(payer_name) <= 120),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  decided_at timestamptz,
  note text check (char_length(note) <= 200)
);
alter table public.topups enable row level security;
drop policy if exists "read own topups" on public.topups;
create policy "read own topups" on public.topups for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "request a topup" on public.topups;
create policy "request a topup" on public.topups for insert to authenticated
  with check ((select auth.uid()) = user_id and status = 'pending' and decided_at is null and note is null);

create table if not exists public.credit_ledger (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  user_id uuid references auth.users (id) on delete set null,
  amount integer not null check (amount <> 0),
  kind text not null check (kind in ('topup', 'rental', 'refund', 'adjust')),
  ref text check (char_length(ref) <= 40),
  label text check (char_length(label) <= 120)
);
alter table public.credit_ledger enable row level security;
drop policy if exists "read own credit" on public.credit_ledger;
create policy "read own credit" on public.credit_ledger for select to authenticated using ((select auth.uid()) = user_id);

-- Your balance: the sum of your own ledger (runs as you, so the rules above apply).
create or replace function public.my_credit()
returns integer language sql stable set search_path = '' as $$
  select coalesce(sum(amount), 0)::integer from public.credit_ledger where user_id = (select auth.uid());
$$;
revoke all on function public.my_credit() from public, anon;
grant execute on function public.my_credit() to authenticated;

create or replace function public.is_team()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from team.admins a where a.user_id = (select auth.uid()));
$$;
revoke all on function public.is_team() from public, anon;
grant execute on function public.is_team() to authenticated;

create or replace function public.team_pending_topups()
returns table (code text, amount integer, bank_ref text, payer_name text, requested_at timestamptz, email text, name text)
language sql stable security definer set search_path = '' as $$
  select t.code, t.amount, t.bank_ref, t.payer_name, t.created_at, u.email::text, (u.raw_user_meta_data ->> 'name')
  from public.topups t left join auth.users u on u.id = t.user_id
  where t.status = 'pending' and public.is_team()
  order by t.created_at;
$$;
revoke all on function public.team_pending_topups() from public, anon;
grant execute on function public.team_pending_topups() to authenticated;

create or replace function public.team_decide_topup(p_code text, p_approve boolean, p_note text default null)
returns json language plpgsql security definer set search_path = '' as $$
declare t public.topups;
begin
  if not public.is_team() then
    raise exception 'Only the SILONG team can approve top-ups.' using errcode = '42501';
  end if;
  update public.topups
     set status = case when p_approve then 'approved' else 'rejected' end, decided_at = now(), note = left(p_note, 200)
   where code = p_code and status = 'pending'
  returning * into t;
  if t.id is null then raise exception 'That top-up was already handled.'; end if;
  if p_approve and t.user_id is not null then
    insert into public.credit_ledger (user_id, amount, kind, ref, label) values (t.user_id, t.amount, 'topup', t.code, 'Top-up by bank transfer');
  end if;
  return json_build_object('code', t.code, 'status', t.status, 'amount', t.amount);
end;
$$;
revoke all on function public.team_decide_topup(text, boolean, text) from public, anon;
grant execute on function public.team_decide_topup(text, boolean, text) to authenticated;
