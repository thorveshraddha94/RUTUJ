-- ============================================================================
-- SUPABASE MULTI-TENANT DATABASE MIGRATION SCRIPT WITH SIGNUP TRIGGER
-- ============================================================================

-- 1. Create Companies Table
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create Profiles Table (Linked to auth.users and companies)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
    username TEXT NOT NULL,
    role TEXT DEFAULT 'admin',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Add company_id Foreign Key to Data Tables
ALTER TABLE public.drivers 
    ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;

ALTER TABLE public.vehicles 
    ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;

ALTER TABLE public.bookings 
    ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;

ALTER TABLE public.bookings 
    ADD COLUMN IF NOT EXISTS notify_client_driver_details BOOLEAN DEFAULT true;

ALTER TABLE public.bookings
    DROP COLUMN IF EXISTS client_name,
    DROP COLUMN IF EXISTS client_contact,
    DROP COLUMN IF EXISTS client_phone;

ALTER TABLE public.bookings
    ADD COLUMN IF NOT EXISTS passenger_name TEXT,
    ADD COLUMN IF NOT EXISTS passenger_phone TEXT,
    ADD COLUMN IF NOT EXISTS booking_reference TEXT,
    ADD COLUMN IF NOT EXISTS notes TEXT;

-- 4. Create Message Logs Table for Client Messaging Dispatch
CREATE TABLE IF NOT EXISTS public.message_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    recipient TEXT NOT NULL,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    status TEXT DEFAULT 'sent',
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.message_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated access to message_logs" ON public.message_logs;
CREATE POLICY "Allow authenticated access to message_logs" ON public.message_logs FOR ALL USING (true);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 5. Automatic User Signup Trigger Function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_company_name TEXT;
    v_username TEXT;
    v_company_id UUID;
BEGIN
    -- Extract metadata passed during signUp()
    v_company_name := COALESCE(NEW.raw_user_meta_data->>'company_name', 'Default Company');
    v_username := COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1));

    -- Find existing company or insert new company record
    SELECT id INTO v_company_id FROM public.companies WHERE LOWER(company_name) = LOWER(v_company_name) LIMIT 1;
    IF v_company_id IS NULL THEN
        INSERT INTO public.companies (company_name)
        VALUES (v_company_name)
        RETURNING id INTO v_company_id;
    END IF;

    -- Insert linked user profile
    INSERT INTO public.profiles (id, company_id, username, role)
    VALUES (NEW.id, v_company_id, v_username, 'admin')
    ON CONFLICT (id) DO UPDATE SET
        company_id = EXCLUDED.company_id,
        username = EXCLUDED.username;

    RETURN NEW;
END;
$$;

-- Trigger Registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. RLS Policies: Public & Authenticated Access
DROP POLICY IF EXISTS "Allow public registration insert on companies" ON public.companies;
CREATE POLICY "Allow public registration insert on companies"
    ON public.companies FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public registration insert on profiles" ON public.profiles;
CREATE POLICY "Allow public registration insert on profiles"
    ON public.profiles FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated select companies" ON public.companies;
CREATE POLICY "Allow authenticated select companies"
    ON public.companies FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow authenticated select profiles" ON public.profiles;
CREATE POLICY "Allow authenticated select profiles"
    ON public.profiles FOR SELECT
    USING (true);

-- 5. Multi-Tenant Helper & RLS Policies
CREATE OR REPLACE FUNCTION public.get_current_company_id()
RETURNS UUID AS $$ SELECT company_id FROM public.profiles WHERE id = auth.uid(); $$ LANGUAGE sql STABLE SECURITY DEFINER;

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tenant Isolation for Drivers" ON public.drivers;
CREATE POLICY "Tenant Isolation for Drivers" ON public.drivers
  FOR ALL USING (company_id = public.get_current_company_id())
  WITH CHECK (company_id = public.get_current_company_id());

DROP POLICY IF EXISTS "Tenant Isolation for Vehicles" ON public.vehicles;
CREATE POLICY "Tenant Isolation for Vehicles" ON public.vehicles
  FOR ALL USING (company_id = public.get_current_company_id())
  WITH CHECK (company_id = public.get_current_company_id());

DROP POLICY IF EXISTS "Tenant Isolation for Bookings" ON public.bookings;
CREATE POLICY "Tenant Isolation for Bookings" ON public.bookings
  FOR ALL USING (company_id = public.get_current_company_id())
  WITH CHECK (company_id = public.get_current_company_id());

DROP POLICY IF EXISTS "Tenant Isolation for Message Logs" ON public.message_logs;
CREATE POLICY "Tenant Isolation for Message Logs" ON public.message_logs
  FOR ALL USING (company_id = public.get_current_company_id())
  WITH CHECK (company_id = public.get_current_company_id());

-- 6. Relational Links & Columns for Data Persistence
ALTER TABLE public.drivers 
  ADD COLUMN IF NOT EXISTS vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL;

ALTER TABLE public.vehicles 
  ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL;

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS passenger_name TEXT,
  ADD COLUMN IF NOT EXISTS passenger_phone TEXT,
  ADD COLUMN IF NOT EXISTS pickup_location TEXT,
  ADD COLUMN IF NOT EXISTS dropoff_location TEXT,
  ADD COLUMN IF NOT EXISTS pickup_time TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
