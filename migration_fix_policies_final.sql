-- Enable RLS
ALTER TABLE warranties ENABLE ROW LEVEL SECURITY;

-- CLEANUP: Drop existing policies to ensure no conflicts or duplicates
DROP POLICY IF EXISTS "Users can see their own warranties" ON warranties;
DROP POLICY IF EXISTS "Users can insert their own warranties" ON warranties;
DROP POLICY IF EXISTS "Users can update their own warranties" ON warranties;
DROP POLICY IF EXISTS "Users can delete their own warranties" ON warranties;

DROP POLICY IF EXISTS "Authenticated Users Select Own" ON warranties;
DROP POLICY IF EXISTS "Authenticated Users Insert Own" ON warranties;
DROP POLICY IF EXISTS "Authenticated Users Update Own" ON warranties;
DROP POLICY IF EXISTS "Authenticated Users Delete Own" ON warranties;

-- RE-CREATE STANDARD AUTHENTICATED POLICIES
-- These allow logged-in users (Google, Email, etc.) to manage their own data

CREATE POLICY "Authenticated Users Select Own" ON warranties
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Authenticated Users Insert Own" ON warranties
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Authenticated Users Update Own" ON warranties
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Authenticated Users Delete Own" ON warranties
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);


-- ENSURE TEST USER POLICIES (For the specific Test ID)
-- These allow public/anon access ONLY for the specific test user ID

DROP POLICY IF EXISTS "Allow Test User Select" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Insert" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Update" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Delete" ON warranties;

CREATE POLICY "Allow Test User Select" ON warranties
  FOR SELECT TO public
  USING (user_id = '00000000-0000-0000-0000-000000000000');

CREATE POLICY "Allow Test User Insert" ON warranties
  FOR INSERT TO public
  WITH CHECK (user_id = '00000000-0000-0000-0000-000000000000');

CREATE POLICY "Allow Test User Update" ON warranties
  FOR UPDATE TO public
  USING (user_id = '00000000-0000-0000-0000-000000000000');

CREATE POLICY "Allow Test User Delete" ON warranties
  FOR DELETE TO public
  USING (user_id = '00000000-0000-0000-0000-000000000000');
