-- 1. Drop Foreign Key Constraint
ALTER TABLE warranties DROP CONSTRAINT IF EXISTS warranties_user_id_fkey;

-- 2. Clean up old policies
DROP POLICY IF EXISTS "Allow Test User Delete" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Insert" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Select" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Update" ON warranties;

DROP POLICY IF EXISTS "Allow Anon Select" ON warranties;
DROP POLICY IF EXISTS "Allow Anon Insert" ON warranties;
DROP POLICY IF EXISTS "Allow Anon Update" ON warranties;
DROP POLICY IF EXISTS "Allow Anon Delete" ON warranties;

-- 3. Re-create Policies for Anon (Dev Mode)
-- Correct Syntax Order: ON table -> FOR command -> TO role -> USING/CHECK

CREATE POLICY "Allow Anon Select" ON warranties
  FOR SELECT TO anon
  USING (true);

CREATE POLICY "Allow Anon Insert" ON warranties
  FOR INSERT TO anon
  WITH CHECK (true);

CREATE POLICY "Allow Anon Update" ON warranties
  FOR UPDATE TO anon
  USING (true);

CREATE POLICY "Allow Anon Delete" ON warranties
  FOR DELETE TO anon
  USING (true);

-- 4. Grant Permissions
GRANT ALL ON warranties TO anon;
GRANT ALL ON warranties TO authenticated;
GRANT ALL ON warranties TO service_role;
