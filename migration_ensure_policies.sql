-- Ensure we drop old policies to be clean
DROP POLICY IF EXISTS "Allow Test User Select" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Insert" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Update" ON warranties;
DROP POLICY IF EXISTS "Allow Test User Delete" ON warranties;

-- Re-create policies targeting PUBLIC (everyone) for the specific Test User ID
-- 00000000-0000-0000-0000-000000000000

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
