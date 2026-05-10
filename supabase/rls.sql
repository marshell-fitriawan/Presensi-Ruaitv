-- Supabase RLS policies for RuaiTV Presensi

alter table public.users enable row level security;
alter table public.attendance enable row level security;
alter table public.settings enable row level security;

drop policy if exists "users_read_own" on public.users;
drop policy if exists "attendance_read_own" on public.attendance;
drop policy if exists "attendance_insert_own" on public.attendance;
drop policy if exists "settings_read_all" on public.settings;
drop policy if exists "settings_update_admin" on public.settings;

-- users: karyawan hanya bisa baca profil sendiri
create policy "users_read_own"
  on public.users for select
  using (id = auth.uid());

-- users: admin bisa baca semua karyawan
create policy "users_read_admin"
  on public.users for select
  using (
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.role = 'admin'
    )
  );

-- attendance: karyawan hanya bisa baca & insert miliknya
create policy "attendance_read_own"
  on public.attendance for select
  using (user_id = auth.uid());

create policy "attendance_insert_own"
  on public.attendance for insert
  with check (user_id = auth.uid());

-- settings: semua user login bisa read
create policy "settings_read_all"
  on public.settings for select
  using (auth.uid() is not null);

-- settings: update hanya admin
create policy "settings_update_admin"
  on public.settings for update
  using (
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.role = 'admin'
    )
  );
