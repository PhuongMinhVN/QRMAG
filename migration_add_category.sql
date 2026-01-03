-- Add category column to warranties table
ALTER TABLE warranties 
ADD COLUMN IF NOT EXISTS category text DEFAULT 'Other';

-- Optional: Create an index for faster filtering by category
CREATE INDEX IF NOT EXISTS idx_warranties_category ON warranties(category);
