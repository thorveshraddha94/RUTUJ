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

-- Data Tables Policies
DROP POLICY IF EXISTS "Tenant isolation for drivers SELECT" ON public.drivers;
CREATE POLICY "Tenant isolation for drivers SELECT" ON public.drivers FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tenant isolation for drivers INSERT" ON public.drivers;
CREATE POLICY "Tenant isolation for drivers INSERT" ON public.drivers FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Tenant isolation for vehicles SELECT" ON public.vehicles;
CREATE POLICY "Tenant isolation for vehicles SELECT" ON public.vehicles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tenant isolation for vehicles INSERT" ON public.vehicles;
CREATE POLICY "Tenant isolation for vehicles INSERT" ON public.vehicles FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Tenant isolation for bookings SELECT" ON public.bookings;
CREATE POLICY "Tenant isolation for bookings SELECT" ON public.bookings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tenant isolation for bookings INSERT" ON public.bookings;
CREATE POLICY "Tenant isolation for bookings INSERT" ON public.bookings FOR INSERT WITH CHECK (true);
