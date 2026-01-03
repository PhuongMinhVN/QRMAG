-- Add seller information columns to warranties table
ALTER TABLE warranties 
ADD COLUMN seller_name text,
ADD COLUMN seller_phone text,
ADD COLUMN seller_address text;
