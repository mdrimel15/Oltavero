
create schema if not exists oltavero_private;
revoke all on schema oltavero_private from public, anon, authenticated;

create table public.oltavero_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null check (char_length(full_name) between 1 and 120),
 created_at timestamptz not null default now()
);
create table public.oltavero_workspaces (
 id uuid primary key default gen_random_uuid(),
 name text not null check (char_length(btrim(name)) between 1 and 120),
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table public.oltavero_memberships (
 workspace_id uuid not null references public.oltavero_workspaces(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'owner' check (role = 'owner'),
 created_at timestamptz not null default now(),
 primary key (workspace_id,user_id)
);
create index oltavero_memberships_user_idx on public.oltavero_memberships(user_id,workspace_id);
create table public.oltavero_workspace_data (
 workspace_id uuid primary key references public.oltavero_workspaces(id) on delete cascade,
 data jsonb not null check (jsonb_typeof(data) = 'object'),
 version integer not null default 0 check (version >= 0),
 updated_at timestamptz not null default now()
);
create table public.oltavero_audit_events (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null references public.oltavero_workspaces(id) on delete cascade,
 actor_id uuid references auth.users(id) on delete set null,
 action text not null,
 created_at timestamptz not null default now()
);
create index oltavero_audit_workspace_time_idx on public.oltavero_audit_events(workspace_id,created_at desc);
create index oltavero_workspaces_creator_idx on public.oltavero_workspaces(created_by);
create index oltavero_audit_actor_idx on public.oltavero_audit_events(actor_id);

alter table public.oltavero_profiles enable row level security;
alter table public.oltavero_workspaces enable row level security;
alter table public.oltavero_memberships enable row level security;
alter table public.oltavero_workspace_data enable row level security;
alter table public.oltavero_audit_events enable row level security;

revoke all on public.oltavero_profiles,public.oltavero_workspaces,public.oltavero_memberships,public.oltavero_workspace_data,public.oltavero_audit_events from anon,authenticated;
grant select,insert on public.oltavero_profiles to authenticated;
grant update(full_name) on public.oltavero_profiles to authenticated;
grant select on public.oltavero_workspaces to authenticated;
grant insert(name,created_by) on public.oltavero_workspaces to authenticated;
grant select on public.oltavero_memberships to authenticated;
grant select on public.oltavero_workspace_data to authenticated;
grant update(data,version) on public.oltavero_workspace_data to authenticated;
grant select on public.oltavero_audit_events to authenticated;

create policy profiles_read_self on public.oltavero_profiles for select to authenticated using (id=(select auth.uid()));
create policy profiles_create_self on public.oltavero_profiles for insert to authenticated with check (id=(select auth.uid()));
create policy profiles_update_self on public.oltavero_profiles for update to authenticated using (id=(select auth.uid())) with check (id=(select auth.uid()));
create policy memberships_read_self on public.oltavero_memberships for select to authenticated using (user_id=(select auth.uid()));
create policy workspaces_read_member on public.oltavero_workspaces for select to authenticated using (
 exists(select 1 from public.oltavero_memberships m where m.workspace_id=id and m.user_id=(select auth.uid()) and m.role='owner')
);
create policy workspaces_create_self on public.oltavero_workspaces for insert to authenticated with check (created_by=(select auth.uid()));
create policy workspace_data_read_owner on public.oltavero_workspace_data for select to authenticated using (
 exists(select 1 from public.oltavero_memberships m where m.workspace_id=oltavero_workspace_data.workspace_id and m.user_id=(select auth.uid()) and m.role='owner')
);
create policy workspace_data_update_owner on public.oltavero_workspace_data for update to authenticated using (
 exists(select 1 from public.oltavero_memberships m where m.workspace_id=oltavero_workspace_data.workspace_id and m.user_id=(select auth.uid()) and m.role='owner')
) with check (
 exists(select 1 from public.oltavero_memberships m where m.workspace_id=oltavero_workspace_data.workspace_id and m.user_id=(select auth.uid()) and m.role='owner')
);
create policy audit_read_owner on public.oltavero_audit_events for select to authenticated using (
 exists(select 1 from public.oltavero_memberships m where m.workspace_id=oltavero_audit_events.workspace_id and m.user_id=(select auth.uid()) and m.role='owner')
);

-- Bootstrap membership atomically: the client cannot grant itself access to an existing workspace.
create function oltavero_private.bootstrap_workspace() returns trigger
language plpgsql security definer set search_path='' as $$
declare user_name text; user_email text;
begin
 if auth.uid() is null or new.created_by <> auth.uid() then
  raise exception 'Authenticated workspace creator required' using errcode='42501';
 end if;
 select coalesce(p.full_name,u.email),u.email into user_name,user_email
 from auth.users u left join public.oltavero_profiles p on p.id=u.id where u.id=auth.uid();
 insert into public.oltavero_memberships(workspace_id,user_id,role) values(new.id,auth.uid(),'owner');
 insert into public.oltavero_workspace_data(workspace_id,data) values(new.id,
 jsonb_build_object(
  'name',new.name,'short',upper(left(new.name,2)),
  'people',jsonb_build_array(jsonb_build_object('id',1,'authUserId',auth.uid(),'name',user_name,'email',user_email,'dept','Executive','role','Owner','status','Active','title','Owner','startDate',current_date)),
  'departments',jsonb_build_array('Executive'),
  'modules',jsonb_build_object('HR',false,'Recruitment',false,'Projects',false,'Operations',false,'Finance',false),
  'settings',jsonb_build_object('legal',new.name,'email',user_email,'location','','timezone','Asia/Dhaka'),
  'events','[]'::jsonb,'projects','[]'::jsonb,'approvals','[]'::jsonb,'customRoles','[]'::jsonb,'permissions','{}'::jsonb
 ));
 insert into public.oltavero_audit_events(workspace_id,actor_id,action) values(new.id,auth.uid(),'Workspace created');
 return new;
end $$;
revoke all on function oltavero_private.bootstrap_workspace() from public,anon,authenticated;
create trigger oltavero_workspace_bootstrap after insert on public.oltavero_workspaces for each row execute function oltavero_private.bootstrap_workspace();

create function oltavero_private.validate_workspace_update() returns trigger
language plpgsql set search_path='' as $$
begin
 if new.version <> old.version+1 then raise exception 'Invalid workspace revision' using errcode='40001'; end if;
 if jsonb_typeof(new.data->'people') is distinct from 'array' or jsonb_typeof(new.data->'departments') is distinct from 'array' or jsonb_typeof(new.data->'modules') is distinct from 'object' then
  raise exception 'Invalid workspace document' using errcode='22023';
 end if;
 if char_length(btrim(new.data->>'name')) not between 1 and 120 then raise exception 'Invalid company name'; end if;
 new.updated_at=now();
 return new;
end $$;
revoke all on function oltavero_private.validate_workspace_update() from public,anon,authenticated;
create trigger oltavero_workspace_validate before update on public.oltavero_workspace_data for each row execute function oltavero_private.validate_workspace_update();

create function oltavero_private.audit_workspace_update() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Authenticated actor required' using errcode='42501'; end if;
 update public.oltavero_workspaces set name=new.data->>'name' where id=new.workspace_id;
 insert into public.oltavero_audit_events(workspace_id,actor_id,action) values(new.workspace_id,auth.uid(),'Workspace updated');
 return new;
end $$;
revoke all on function oltavero_private.audit_workspace_update() from public,anon,authenticated;
create trigger oltavero_workspace_audit after update on public.oltavero_workspace_data for each row execute function oltavero_private.audit_workspace_update();

-- Client-supplied UUIDs allow an insert without RETURNING before bootstrap completes.
grant insert(id) on public.oltavero_workspaces to authenticated;
