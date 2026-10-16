-- ============================================================
-- Run this ONCE in Supabase: Dashboard > SQL Editor > New query > paste > Run
-- ============================================================

-- Table: one row per store (menu, wifi, review link, branding)
create table if not exists store_config (
  id text primary key default 'default',
  store_name text not null default 'My Store',
  tagline text default '',
  wifi_ssid text default '',
  wifi_password text default '',
  review_link text default '',
  menu_text text default '',
  updated_at timestamptz not null default now()
);

-- Seed it with the Kopi Senja demo data — edit or delete this row later
-- from the admin dashboard once it's deployed.
insert into store_config (id, store_name, tagline, wifi_ssid, wifi_password, review_link, menu_text)
values (
  'default',
  'Kopi Senja',
  'Slow coffee, warm conversations. Jl. Kemang Raya 21',
  'KopiSenja_Guest',
  'senja2026!',
  'https://search.google.com/local/writereview?placeid=REPLACE_WITH_PLACE_ID',
  $$Coffee & Drinks|Kopi Susu Senja|Rp 28.000|Double espresso, fresh milk, palm sugar syrup.|Best seller
Coffee & Drinks|Matcha Cloud|Rp 34.000|Uji matcha, milk, and a light vanilla cold foam.|Contains: Dairy
Coffee & Drinks|Long Black|Rp 24.000|Double shot over ice-cold water.|
Brunch & Light Plates|Smashed Avocado on Sourdough|Rp 42.000|Heritage tomatoes, chilli flakes, lime, toasted seeds.|Vegan
Brunch & Light Plates|Burford Brown Eggs Royale|Rp 55.000|Poached eggs, smoked salmon, hollandaise, toasted muffin.|Contains: Gluten, Eggs, Fish
Pastry|Butter Croissant|Rp 22.000|Laminated 36 hours, baked fresh each morning.|Contains: Gluten, Dairy
Pastry|Banana Bread Slice|Rp 26.000|Walnut, dark chocolate chunks.|Contains: Gluten, Nuts$$
)
on conflict (id) do nothing;

alter table store_config enable row level security;

-- Anyone (customers tapping the NFC card) can read the store's config.
create policy "Anyone can read store config"
on store_config for select
using (true);

-- Only a signed-in admin (created in Authentication > Users) can change it.
create policy "Only signed-in admins can update store config"
on store_config for update
using (auth.role() = 'authenticated');


-- Table: anonymous feedback submitted by customers
create table if not exists feedback (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  photo_url text,
  created_at timestamptz not null default now()
);

alter table feedback enable row level security;

-- Anyone can submit feedback (write-only, no identity attached).
create policy "Anyone can submit feedback"
on feedback for insert
with check (true);

-- Only a signed-in admin can read the feedback that comes in.
create policy "Only signed-in admins can read feedback"
on feedback for select
using (auth.role() = 'authenticated');
