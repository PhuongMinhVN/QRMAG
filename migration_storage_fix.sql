-- 1. Create Bucket if not exists (Idempotent)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('warranty_images', 'warranty_images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow Anon Select Storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow Anon Insert Storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow Anon Update Storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow Anon Delete Storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow Public Select Storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow Public Insert Storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow Public Update Storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow Public Delete Storage" ON storage.objects;

-- 3. Create Permissive Policies for 'warranty_images' bucket
-- Allow Select (View) for everyone
CREATE POLICY "Allow Public Select Storage" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'warranty_images');

-- Allow Insert (Upload) for everyone
CREATE POLICY "Allow Public Insert Storage" ON storage.objects
  FOR INSERT TO public
  WITH CHECK (bucket_id = 'warranty_images');

-- Allow Update for everyone
CREATE POLICY "Allow Public Update Storage" ON storage.objects
  FOR UPDATE TO public
  USING (bucket_id = 'warranty_images');

-- Allow Delete for everyone
CREATE POLICY "Allow Public Delete Storage" ON storage.objects
  FOR DELETE TO public
  USING (bucket_id = 'warranty_images');

-- 4. Grant Permissions on storage schema
GRANT ALL ON SCHEMA storage TO anon;
GRANT ALL ON SCHEMA storage TO authenticated;
GRANT ALL ON SCHEMA storage TO service_role;
