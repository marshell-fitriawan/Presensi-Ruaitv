-- Seed starter app data.
-- Important: Do not insert directly into auth.* tables on hosted Supabase.
-- Create auth users via Dashboard, Edge Function, or /auth/v1/signup first.

insert into public.users (id, name, email, department, role, is_active)
select id, 'Admin RuaiTV', email, 'HR', 'admin', true
from auth.users
where email = 'admin@ruaitv.local'
on conflict (id) do update set
  name = excluded.name,
  email = excluded.email,
  department = excluded.department,
  role = excluded.role,
  is_active = excluded.is_active;

insert into public.users (id, name, email, department, role, is_active)
select id, 'Karyawan RuaiTV', email, 'Ops', 'employee', true
from auth.users
where email = 'employee@ruaitv.local'
on conflict (id) do update set
  name = excluded.name,
  email = excluded.email,
  department = excluded.department,
  role = excluded.role,
  is_active = excluded.is_active;

insert into public.settings (key, lat, lng, radius_meters, updated_by)
select 'office_location', -0.006625056302077418, 109.36360448257791, 50,
       (select id from auth.users where email = 'admin@ruaitv.local')
on conflict (key) do update set
  lat = excluded.lat,
  lng = excluded.lng,
  radius_meters = excluded.radius_meters,
  updated_by = excluded.updated_by;
