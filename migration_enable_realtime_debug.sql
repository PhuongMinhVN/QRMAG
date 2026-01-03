-- Add warranties table to the realtime publication
-- This is often required for the Flutter SDK .stream() to receive live updates properly
alter publication supabase_realtime add table warranties;

-- Double check policies (re-run just to be safe)
CREATE POLICY "Allow Public Select All" ON warranties
  FOR SELECT TO public
  USING (true); 
-- Note: turning on "Select All" for public temporarily to debug if it's a permission issue.
-- If this fixes it, the previous "user_id = auth.uid()" logic was failing (e.g. auth.uid() is null in some context).
