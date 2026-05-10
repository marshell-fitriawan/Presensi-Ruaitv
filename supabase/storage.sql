-- Create private storage bucket for face photos
insert into storage.buckets (id, name, "public")
values ('face-photos', 'face-photos', false)
on conflict (id) do nothing;
