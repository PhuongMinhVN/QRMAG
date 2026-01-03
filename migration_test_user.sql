-- 1. Drop Foreign Key Constraint to allow non-auth users (Test User)
ALTER TABLE warranties DROP CONSTRAINT IF EXISTS warranties_user_id_fkey;

-- 2. Create Policy for Test User (ID: 00000000-0000-0000-0000-000000000000)
-- Allow Select
CREATE POLICY "Allow Test User Select" ON warranties
  FOR SELECT USING (user_id = '00000000-0000-0000-0000-000000000000');

-- Allow Insert
CREATE POLICY "Allow Test User Insert" ON warranties
  FOR INSERT WITH CHECK (user_id = '00000000-0000-0000-0000-000000000000');

-- Allow Update
CREATE POLICY "Allow Test User Update" ON warranties
  FOR UPDATE USING (user_id = '00000000-0000-0000-0000-000000000000');

-- Allow Delete
CREATE POLICY "Allow Test User Delete" ON warranties
  FOR DELETE USING (user_id = '00000000-0000-0000-0000-000000000000');
