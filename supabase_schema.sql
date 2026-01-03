-- Create Warranties Table
create table warranties (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  product_name text not null,
  purchase_date date not null,
  warranty_duration_months int not null,
  warranty_end_date date not null,
  product_image_url text,
  product_code text,
  seller_name text,
  seller_phone text,
  seller_address text,
  created_at timestamptz default now()
);

-- Enable Row Level Security (RLS)
alter table warranties enable row level security;

-- Create Policies
-- Users can only see their own warranties
create policy "Users can see their own warranties" on warranties
  for select using (auth.uid() = user_id);

-- Users can only insert their own warranties
create policy "Users can insert their own warranties" on warranties
  for insert with check (auth.uid() = user_id);

-- Users can update their own warranties (if needed in future)
create policy "Users can update their own warranties" on warranties
  for update using (auth.uid() = user_id);

-- Users can delete their own warranties (if needed in future)
create policy "Users can delete their own warranties" on warranties
  for delete using (auth.uid() = user_id);

-- Storage Bucket Setup (Run this if 'warranty_images' bucket doesn't exist)
insert into storage.buckets (id, name, public) 
values ('warranty_images', 'warranty_images', true)
on conflict (id) do nothing;

-- Storage Policies
-- Allow public access to view images (so they can be displayed in app)
create policy "Public Access" on storage.objects 
  for select using ( bucket_id = 'warranty_images' );

-- Allow authenticated users to upload images
create policy "Authenticated Upload" on storage.objects 
  for insert with check ( 
    bucket_id = 'warranty_images' 
    and auth.role() = 'authenticated' 
  );
