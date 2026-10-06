-- ============================================================
-- EXPENSE TRACKER — FULL DATABASE RESET & SCHEMA (Supabase)
-- ============================================================
-- Run in: Supabase Dashboard → SQL Editor (single run).
-- WARNING: Drops app tables and data in public schema for this app.
-- Keeps auth.users intact (users remain; profile rows are recreated on next login if needed).
-- ============================================================

-- ── 0. TEARDOWN (order respects FKs) ──────────────────────

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

DROP TRIGGER IF EXISTS update_profiles_timestamp ON public.profiles;
DROP TRIGGER IF EXISTS update_expenses_timestamp ON public.expenses;
DROP TRIGGER IF EXISTS update_limits_timestamp ON public.spending_limits;
DROP TRIGGER IF EXISTS update_settings_timestamp ON public.user_settings;

DROP TABLE IF EXISTS public.user_settings CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.budget_alerts CASCADE;
DROP TABLE IF EXISTS public.spending_limits CASCADE;
DROP TABLE IF EXISTS public.expenses CASCADE;
DROP TABLE IF EXISTS public.family_members CASCADE;
DROP TABLE IF EXISTS public.families CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP FUNCTION IF EXISTS public.send_notification_to_user(uuid, text, text, int, text, text);
DROP FUNCTION IF EXISTS public.find_user_id_by_email(text);
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;

-- ── 1. TABLES ─────────────────────────────────────────────

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT NOT NULL,
  avatar_url TEXT,
  currency TEXT DEFAULT 'BDT',
  is_family_mode BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT profiles_email_unique UNIQUE (email)
);

CREATE INDEX idx_profiles_email ON public.profiles(email);

CREATE TABLE public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon_code_point INT NOT NULL,
  color_value BIGINT NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX categories_user_name_unique
  ON public.categories (user_id, name) NULLS NOT DISTINCT;

CREATE INDEX idx_categories_user ON public.categories(user_id);

CREATE TABLE public.families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT 'My Family',
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  joined_at TIMESTAMPTZ,
  UNIQUE (family_id, user_id)
);

CREATE INDEX idx_family_members_user ON public.family_members(user_id);
CREATE INDEX idx_family_members_family ON public.family_members(family_id);

CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL CHECK (amount > 0),
  category TEXT NOT NULL,
  category_icon INT NOT NULL,
  category_color BIGINT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  is_income BOOLEAN NOT NULL DEFAULT FALSE,
  note TEXT,
  user_name TEXT,
  is_family BOOLEAN NOT NULL DEFAULT FALSE,
  family_id UUID REFERENCES public.families(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_expenses_user ON public.expenses(user_id);
CREATE INDEX idx_expenses_date ON public.expenses(date DESC);
CREATE INDEX idx_expenses_category ON public.expenses(category);
CREATE INDEX idx_expenses_user_date ON public.expenses(user_id, date DESC);
CREATE INDEX idx_expenses_family ON public.expenses(family_id);

CREATE TABLE public.spending_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type INT NOT NULL CHECK (type IN (0, 1, 2)),
  amount DOUBLE PRECISION NOT NULL CHECK (amount > 0),
  category TEXT,
  is_family BOOLEAN NOT NULL DEFAULT FALSE,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_limits_user ON public.spending_limits(user_id);

CREATE TABLE public.budget_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  limit_id UUID NOT NULL REFERENCES public.spending_limits(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  level INT NOT NULL CHECK (level IN (0, 1, 2, 3)),
  amount_spent DOUBLE PRECISION NOT NULL,
  amount_limit DOUBLE PRECISION NOT NULL,
  category TEXT,
  is_family BOOLEAN NOT NULL DEFAULT FALSE,
  is_dismissed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_user ON public.budget_alerts(user_id);
CREATE INDEX idx_alerts_limit ON public.budget_alerts(limit_id);

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type INT NOT NULL CHECK (type IN (0, 1, 2, 3)),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  related_email TEXT,
  invite_status TEXT CHECK (invite_status IN ('pending', 'accepted', 'rejected') OR invite_status IS NULL),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);

CREATE TABLE public.user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  theme_mode TEXT NOT NULL DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')),
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  sync_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. RLS ────────────────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spending_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY profiles_select_own
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY profiles_select_family_peers
  ON public.profiles FOR SELECT
  USING (
    id IN (
      SELECT fm2.user_id
      FROM public.family_members fm1
      JOIN public.family_members fm2 ON fm1.family_id = fm2.family_id
      WHERE fm1.user_id = auth.uid()
        AND fm1.status = 'accepted'
        AND fm2.status = 'accepted'
    )
  );

CREATE POLICY profiles_update_own
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY profiles_insert_own
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- categories
CREATE POLICY categories_select_defaults
  ON public.categories FOR SELECT
  USING (is_default = TRUE AND user_id IS NULL);

CREATE POLICY categories_select_own
  ON public.categories FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY categories_select_family_shared
  ON public.categories FOR SELECT
  USING (
    user_id IS NOT NULL
    AND user_id <> auth.uid()
    AND user_id IN (
      SELECT fm2.user_id
      FROM public.family_members fm1
      JOIN public.family_members fm2 ON fm1.family_id = fm2.family_id
      WHERE fm1.user_id = auth.uid()
        AND fm1.status = 'accepted'
        AND fm2.status = 'accepted'
        AND fm2.user_id <> auth.uid()
    )
  );

CREATE POLICY categories_insert_own
  ON public.categories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY categories_update_own
  ON public.categories FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY categories_delete_own_nonsystem
  ON public.categories FOR DELETE
  USING (auth.uid() = user_id AND is_default = FALSE);

-- expenses
CREATE POLICY expenses_all_own
  ON public.expenses FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY expenses_select_family
  ON public.expenses FOR SELECT
  USING (
    is_family = TRUE
    AND family_id IN (
      SELECT family_id FROM public.family_members
      WHERE user_id = auth.uid() AND status = 'accepted'
    )
  );

-- spending_limits & budget_alerts & notifications & user_settings
CREATE POLICY spending_limits_all_own
  ON public.spending_limits FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY budget_alerts_all_own
  ON public.budget_alerts FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY notifications_all_own
  ON public.notifications FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_settings_all_own
  ON public.user_settings FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- families
CREATE POLICY families_all_owner
  ON public.families FOR ALL
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY families_select_member
  ON public.families FOR SELECT
  USING (
    id IN (
      SELECT family_id FROM public.family_members
      WHERE user_id = auth.uid() AND status = 'accepted'
    )
  );

-- family_members (critical: see co-members, not only your row)
CREATE POLICY family_members_select_visible
  ON public.family_members FOR SELECT
  USING (
    family_id IN (
      SELECT family_id FROM public.family_members
      WHERE user_id = auth.uid() AND status = 'accepted'
    )
  );

CREATE POLICY family_members_insert_owner
  ON public.family_members FOR INSERT
  WITH CHECK (
    family_id IN (SELECT id FROM public.families WHERE owner_id = auth.uid())
  );

CREATE POLICY family_members_update_owner
  ON public.family_members FOR UPDATE
  USING (
    family_id IN (SELECT id FROM public.families WHERE owner_id = auth.uid())
  )
  WITH CHECK (
    family_id IN (SELECT id FROM public.families WHERE owner_id = auth.uid())
  );

CREATE POLICY family_members_delete_owner
  ON public.family_members FOR DELETE
  USING (
    family_id IN (SELECT id FROM public.families WHERE owner_id = auth.uid())
  );

CREATE POLICY family_members_update_self
  ON public.family_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ── 3. FUNCTIONS & TRIGGERS ────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_profiles_timestamp
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_expenses_timestamp
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_limits_timestamp
  BEFORE UPDATE ON public.spending_limits
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_settings_timestamp
  BEFORE UPDATE ON public.user_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(COALESCE(NEW.email, 'user@local'), '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Invite: resolve email → user id without exposing all profiles (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.find_user_id_by_email(p_email text)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id
  FROM public.profiles
  WHERE lower(trim(both from email)) = lower(trim(both from p_email))
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.find_user_id_by_email(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.find_user_id_by_email(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.find_user_id_by_email(text) TO service_role;

-- Push notification row to another user (family invites, etc.)
CREATE OR REPLACE FUNCTION public.send_notification_to_user(
  p_recipient_id uuid,
  p_title text,
  p_body text,
  p_type int,
  p_related_email text DEFAULT NULL,
  p_invite_status text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.notifications (
    user_id, title, body, type, is_read, related_email, invite_status
  ) VALUES (
    p_recipient_id, p_title, p_body, p_type, FALSE, p_related_email, p_invite_status
  );
END;
$$;

REVOKE ALL ON FUNCTION public.send_notification_to_user(uuid, text, text, int, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_notification_to_user(uuid, text, text, int, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_notification_to_user(uuid, text, text, int, text, text) TO service_role;

-- ── 4. GRANTS (fixes empty client reads when privileges were missing) ──

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;

GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

-- ── 5. SEED DEFAULT CATEGORIES (system, user_id NULL) ─────

INSERT INTO public.categories (user_id, name, icon_code_point, color_value, is_default)
VALUES
  (NULL, 'Food',           58746,  4294922091, TRUE),
  (NULL, 'Shopping',       61207,  4285071079, TRUE),
  (NULL, 'Transport',      57815,  4278241993, TRUE),
  (NULL, 'Bills',          61284,  4294951170, TRUE),
  (NULL, 'Entertainment',  58844,  4292297619, TRUE),
  (NULL, 'Health',         61705,  4278237332, TRUE),
  (NULL, 'Salary',         57519,  4283830212, TRUE),
  (NULL, 'Education',      59404,  4285812735, TRUE);

-- ── 6. BACKFILL profiles + settings for EXISTING auth.users ──
-- (So you do not lose logins after reset; re-login will load data again.)

INSERT INTO public.profiles (id, email, full_name)
SELECT u.id,
       COALESCE(u.email, ''),
       COALESCE(u.raw_user_meta_data->>'full_name', split_part(COALESCE(u.email, 'user'), '@', 1))
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
  AND COALESCE(u.email, '') <> '';

INSERT INTO public.user_settings (user_id)
SELECT u.id
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.user_settings s WHERE s.user_id = u.id);

-- ============================================================
-- DONE
-- ============================================================
-- 1) Run once in SQL Editor. Tables are empty except seeds + backfilled profiles.
-- 2) Expenses/limits/etc. were dropped — re-sync from app or accept data loss.
-- 3) Flutter: getUserIdByEmail uses RPC find_user_id_by_email; invites use send_notification_to_user.
-- 4) If triggers fail with EXECUTE FUNCTION, change to EXECUTE PROCEDURE (older Postgres).
-- ============================================================
