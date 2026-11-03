-- Configuración global de apariencia de Revista Digital Clínica Vita
-- Ejecutar una sola vez en Supabase > SQL Editor > New query.

create table if not exists public.configuracion_revista (
  id text primary key check (id = 'global'),
  tema text not null default 'vita'
    check (tema in ('vita','cielo','lavanda','natural','arena')),
  fondo_url text not null default '',
  actualizado_en timestamptz not null default now(),
  actualizado_por uuid
);

alter table public.configuracion_revista enable row level security;

drop policy if exists "La apariencia es pública para lectura" on public.configuracion_revista;
create policy "La apariencia es pública para lectura"
on public.configuracion_revista for select
to anon, authenticated
using (true);

drop policy if exists "Solo administradora cambia la apariencia" on public.configuracion_revista;
create policy "Solo administradora cambia la apariencia"
on public.configuracion_revista for all
to authenticated
using (auth.uid() = '774846a1-4083-48ad-a19e-8a97b8687ada'::uuid)
with check (auth.uid() = '774846a1-4083-48ad-a19e-8a97b8687ada'::uuid);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'revista-fondos',
  'revista-fondos',
  true,
  8388608,
  array['image/png','image/jpeg','image/webp']
)
on conflict (id) do update
set public = true,
    file_size_limit = 8388608,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Fondos de revista visibles públicamente" on storage.objects;
create policy "Fondos de revista visibles públicamente"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'revista-fondos');

drop policy if exists "Solo administradora carga fondos" on storage.objects;
create policy "Solo administradora carga fondos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'revista-fondos'
  and auth.uid() = '774846a1-4083-48ad-a19e-8a97b8687ada'::uuid
);

drop policy if exists "Solo administradora actualiza fondos" on storage.objects;
create policy "Solo administradora actualiza fondos"
on storage.objects for update
to authenticated
using (
  bucket_id = 'revista-fondos'
  and auth.uid() = '774846a1-4083-48ad-a19e-8a97b8687ada'::uuid
)
with check (
  bucket_id = 'revista-fondos'
  and auth.uid() = '774846a1-4083-48ad-a19e-8a97b8687ada'::uuid
);

drop policy if exists "Solo administradora elimina fondos" on storage.objects;
create policy "Solo administradora elimina fondos"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'revista-fondos'
  and auth.uid() = '774846a1-4083-48ad-a19e-8a97b8687ada'::uuid
);

insert into public.configuracion_revista (id, tema, fondo_url)
values ('global','vita','')
on conflict (id) do nothing;
