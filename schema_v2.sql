-- ============================================================
-- V2: multi-client dashboard (clients, locations, menu, feedback management)
-- Run this ONCE in Supabase AFTER schema.sql:
--   Dashboard > SQL Editor > New query > paste > Run
-- Safe to re-run: every statement is idempotent.
-- ============================================================

-- ---------- Admins ----------
-- Only users listed here can manage the dashboard. Being "signed in" is
-- not enough, so a stranger who signs up with the public anon key gets nothing.
create table if not exists admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table admin_users enable row level security;

drop policy if exists "Admins can see themselves" on admin_users;
create policy "Admins can see themselves"
on admin_users for select
using (auth.uid() = user_id);

create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public
as $$ select exists (select 1 from admin_users where user_id = auth.uid()) $$;

-- Make the existing account an admin. Add more staff later with the same line.
insert into admin_users (user_id)
select id from auth.users where email = 'dimas123prabowo@gmail.com'
on conflict do nothing;


-- ---------- Clients (businesses using the NFC hub) ----------
create table if not exists clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  contact_name text default '',
  email text default '',
  phone text default '',
  plan text not null default 'free',
  status text not null default 'active' check (status in ('active', 'inactive')),
  notes text default '',
  created_at timestamptz not null default now()
);
alter table clients enable row level security;

drop policy if exists "Admins manage clients" on clients;
create policy "Admins manage clients"
on clients for all
using (is_admin()) with check (is_admin());


-- ---------- Locations (one outlet / table-card target per row) ----------
create table if not exists locations (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id) on delete cascade,
  name text not null,
  address text default '',
  wifi_ssid text default '',
  wifi_password text default '',
  google_place_id text default '',
  google_review_url text default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists locations_client_id_idx on locations(client_id);
alter table locations enable row level security;

-- Customers tapping the NFC card read the location (incl. Wi-Fi) directly.
drop policy if exists "Anyone can read active locations" on locations;
create policy "Anyone can read active locations"
on locations for select
using (is_active);

drop policy if exists "Admins manage locations" on locations;
create policy "Admins manage locations"
on locations for all
using (is_admin()) with check (is_admin());


-- ---------- Menu items ----------
create table if not exists menu_items (
  id uuid primary key default gen_random_uuid(),
  location_id uuid not null references locations(id) on delete cascade,
  category text not null default 'Menu',
  name text not null,
  price numeric(12, 0),
  description text default '',
  tags text default '',
  is_available boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists menu_items_location_id_idx on menu_items(location_id);
alter table menu_items enable row level security;

drop policy if exists "Anyone can read menu items" on menu_items;
create policy "Anyone can read menu items"
on menu_items for select
using (true);

drop policy if exists "Admins manage menu items" on menu_items;
create policy "Admins manage menu items"
on menu_items for all
using (is_admin()) with check (is_admin());


-- ---------- Feedback: link to a location + management fields ----------
alter table feedback add column if not exists location_id uuid references locations(id) on delete set null;
alter table feedback add column if not exists rating smallint check (rating between 1 and 5);
alter table feedback add column if not exists source text not null default 'nfc' check (source in ('nfc', 'google'));
alter table feedback add column if not exists author_name text default '';
alter table feedback add column if not exists status text not null default 'new' check (status in ('new', 'read', 'replied', 'resolved'));
alter table feedback add column if not exists admin_reply text default '';
alter table feedback add column if not exists replied_at timestamptz;
create index if not exists feedback_location_id_idx on feedback(location_id);

-- Replace the old "any signed-in user" policies with admin-only ones.
drop policy if exists "Only signed-in admins can read feedback" on feedback;
drop policy if exists "Admins read feedback" on feedback;
create policy "Admins read feedback" on feedback for select using (is_admin());

drop policy if exists "Admins update feedback" on feedback;
create policy "Admins update feedback" on feedback for update using (is_admin()) with check (is_admin());

drop policy if exists "Admins delete feedback" on feedback;
create policy "Admins delete feedback" on feedback for delete using (is_admin());

-- Admins can also insert (e.g. logging a Google review manually); the
-- existing "Anyone can submit feedback" policy already covers customers.

drop policy if exists "Only signed-in admins can update store config" on store_config;
create policy "Only signed-in admins can update store config"
on store_config for update
using (is_admin());


-- ---------- One-time migration of the Kopi Senja demo row ----------
do $$
declare
  cfg store_config%rowtype;
  c_id uuid;
  l_id uuid;
begin
  if exists (select 1 from clients) then return; end if;
  select * into cfg from store_config where id = 'default';
  if not found then return; end if;

  insert into clients (name, plan, status)
  values (coalesce(nullif(cfg.store_name, ''), 'Kopi Senja'), 'free', 'active')
  returning id into c_id;

  insert into locations (client_id, name, address, wifi_ssid, wifi_password, google_review_url)
  values (c_id, coalesce(nullif(cfg.store_name, ''), 'Kopi Senja'), coalesce(cfg.tagline, ''),
          coalesce(cfg.wifi_ssid, ''), coalesce(cfg.wifi_password, ''), coalesce(cfg.review_link, ''))
  returning id into l_id;

  insert into menu_items (location_id, category, name, price, description, tags, sort_order)
  select l_id,
         trim(split_part(line, '|', 1)),
         trim(split_part(line, '|', 2)),
         nullif(regexp_replace(split_part(line, '|', 3), '[^0-9]', '', 'g'), '')::numeric,
         trim(split_part(line, '|', 4)),
         trim(split_part(line, '|', 5)),
         ord
  from regexp_split_to_table(coalesce(cfg.menu_text, ''), E'\n') with ordinality as t(line, ord)
  where trim(line) <> '' and trim(split_part(line, '|', 2)) <> '';

  update feedback set location_id = l_id where location_id is null;
end $$;
