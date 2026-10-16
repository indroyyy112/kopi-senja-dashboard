# Kopi Senja NFC Hub — deployable starter kit

Two static pages + a Supabase backend:

- **`index.html`** — the customer-facing hub page (what opens when someone taps the NFC card). Home, Loyalty Stamps, Menu, Wi-Fi, Anonymous Feedback.
- **`admin.html`** — the dashboard where you log in and edit the store name, Wi-Fi, menu, and read incoming feedback.
- **`config.js`** — the one file you edit with your own Supabase project's URL/key.
- **`schema.sql`** — run this once in Supabase to create the tables.

No build step, no framework — plain HTML/CSS/JS you can open directly in a browser or drop on any static host.

## 1. Create a free Supabase project

1. Go to [supabase.com](https://supabase.com) → sign up → **New project**.
2. Wait ~2 minutes for it to provision.
3. In the left sidebar go to **SQL Editor** → **New query**, paste in the entire contents of `schema.sql`, and click **Run**. This creates the `store_config` table (seeded with the Kopi Senja demo data) and the `feedback` table, with the right read/write permissions already set.

## 2. Create your admin login

1. In the sidebar go to **Authentication → Users → Add user**.
2. Enter your own email and a password. This is the account you'll use to log into `admin.html`.
3. You can add more staff accounts the same way later.

## 3. Connect the pages to your project

1. In the sidebar go to **Project Settings → API**.
2. Copy the **Project URL** and the **anon public** key.
3. Open `config.js` and paste them in:
   ```js
   const SUPABASE_URL = "https://xxxxxxxx.supabase.co";
   const SUPABASE_ANON_KEY = "eyJhbGciOi...";
   ```
   The anon key is safe to expose publicly — it only allows what the SQL policies allow (read the store config, submit feedback; only a signed-in user can edit).

## 4. Try it locally first

Just open `index.html` in a browser (double-click it, or run a tiny local server: `python3 -m http.server` in this folder, then visit `http://localhost:8000`). It should show "Kopi Senja" with the seeded menu/Wi-Fi. Open `admin.html`, log in, change the Wi-Fi password, save — then reload `index.html` and confirm it updated.

## 5. Push to GitHub and deploy

```bash
git init
git add .
git commit -m "NFC hub starter"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

Then deploy the static files anywhere — a few easy options:

- **GitHub Pages** (free): repo Settings → Pages → deploy from the `main` branch, root folder. Your site appears at `https://<your-username>.github.io/<your-repo>/`.
- **Netlify / Vercel** (free): connect the GitHub repo, no build command needed (static site), deploy.
- **Your own server**: copy `index.html`, `admin.html`, `config.js` to any web server's public folder (nginx, Apache, etc). No server-side code required — it's just static files talking to Supabase over HTTPS.

## 6. Write the NFC card

Once deployed, note the customer-facing URL, e.g. `https://your-site.com/index.html`.

1. Install **NFC Tools** (free, Android/iOS).
2. Write → Add a record → URL/Text → paste your live `index.html` URL.
3. Tap your phone to the NFC card → Write.
4. Test-tap with both an Android phone and an iPhone before sticking it on a table.

## What's simplified in this starter kit (compared to the full PRD)

- **Single store only.** The `store_config` table has one row (`id = 'default'`). Multi-tenant (many stores, one per URL slug) needs a `merchant_id`/slug column and a small routing change — happy to help with that next.
- **Menu format is a plain-text mini-language** (`Category | Name | Price | Description | Tags` per line) rather than a full visual menu editor, to keep the admin dashboard simple. It's readable and diffable, and easy to upgrade to a proper form-based editor later.
- **Feedback has no photo upload wired up yet** — the field was removed from this version; Supabase Storage can add that back in.
- **No rate limiting/anti-spam** on the feedback form beyond what Supabase gives by default.
- **Real photos:** menu item photos are placeholder gradients. To use real photos, upload them to Supabase Storage (or any image host) and add a `photo_url` column to read in `index.html`.

## Costs

Supabase's free tier covers this comfortably for a single store or a handful of stores (500 MB database, 50,000 monthly active users on auth). You will not need a paid plan until you're running this at real scale across many stores.
