-- Supabase schema for RuaiTV Presensi

create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  email text not null,
  nip text,
  employee_id text,
  department text,
  role text not null default 'employee',
  face_embedding_id text,
  face_photo_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists users_nip_idx on public.users (nip);
create index if not exists users_employee_id_idx on public.users (employee_id);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  type text not null,
  timestamp timestamptz not null default now(),
  lat double precision,
  lng double precision,
  distance double precision,
  location_valid boolean not null default false,
  face_valid boolean not null default false,
  status text not null default 'rejected',
  photo_url text
);

create index if not exists attendance_user_id_idx on public.attendance (user_id);
create index if not exists attendance_timestamp_idx on public.attendance (timestamp desc);

create table if not exists public.settings (
  key text primary key,
  lat double precision,
  lng double precision,
  radius_meters double precision,
  updated_by uuid references public.users (id)
);
