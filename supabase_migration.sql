-- ============================================================================
-- SUPABASE MULTI-TENANT DATABASE MIGRATION SCRIPT
-- ============================================================================

-- 1. Create Companies Table
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create Profiles Table (Linked to auth.users and companies)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    email TEXT,
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

-- 5. RLS Policies: Public Signup & Registration Inserts
DROP POLICY IF EXISTS "Allow public registration insert on companies" ON public.companies;
CREATE POLICY "Allow public registration insert on companies"
    ON public.companies FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public registration insert on profiles" ON public.profiles;
CREATE POLICY "Allow public registration insert on profiles"
    ON public.profiles FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow user select own profile" ON public.profiles;
CREATE POLICY "Allow user select own profile"
    ON public.profiles FOR SELECT
    USING (id = auth.uid());

DROP POLICY IF EXISTS "Allow company member select company" ON public.companies;
CREATE POLICY "Allow company member select company"
    ON public.companies FOR SELECT
    USING (id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- 6. Tenant-Scoped RLS Policies for Data Tables (Drivers, Vehicles, Bookings)
-- Drivers
DROP POLICY IF EXISTS "Tenant isolation for drivers SELECT" ON public.drivers;
CREATE POLICY "Tenant isolation for drivers SELECT"
    ON public.drivers FOR SELECT
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for drivers INSERT" ON public.drivers;
CREATE POLICY "Tenant isolation for drivers INSERT"
    ON public.drivers FOR INSERT
    WITH CHECK (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for drivers UPDATE" ON public.drivers;
CREATE POLICY "Tenant isolation for drivers UPDATE"
    ON public.drivers FOR UPDATE
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for drivers DELETE" ON public.drivers;
CREATE POLICY "Tenant isolation for drivers DELETE"
    ON public.drivers FOR DELETE
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- Vehicles
DROP POLICY IF EXISTS "Tenant isolation for vehicles SELECT" ON public.vehicles;
CREATE POLICY "Tenant isolation for vehicles SELECT"
    ON public.vehicles FOR SELECT
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for vehicles INSERT" ON public.vehicles;
CREATE POLICY "Tenant isolation for vehicles INSERT"
    ON public.vehicles FOR INSERT
    WITH CHECK (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for vehicles UPDATE" ON public.vehicles;
CREATE POLICY "Tenant isolation for vehicles UPDATE"
    ON public.vehicles FOR UPDATE
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for vehicles DELETE" ON public.vehicles;
CREATE POLICY "Tenant isolation for vehicles DELETE"
    ON public.vehicles FOR DELETE
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

-- Bookings
DROP POLICY IF EXISTS "Tenant isolation for bookings SELECT" ON public.bookings;
CREATE POLICY "Tenant isolation for bookings SELECT"
    ON public.bookings FOR SELECT
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for bookings INSERT" ON public.bookings;
CREATE POLICY "Tenant isolation for bookings INSERT"
    ON public.bookings FOR INSERT
    WITH CHECK (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for bookings UPDATE" ON public.bookings;
CREATE POLICY "Tenant isolation for bookings UPDATE"
    ON public.bookings FOR UPDATE
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant isolation for bookings DELETE" ON public.bookings;
CREATE POLICY "Tenant isolation for bookings DELETE"
    ON public.bookings FOR DELETE
    USING (company_id = (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
