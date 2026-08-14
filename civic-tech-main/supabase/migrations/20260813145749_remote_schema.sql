-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

DROP EXTENSION pg_net;

COMMENT ON SCHEMA public IS NULL;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE UPDATE ON SEQUENCES FROM anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES FROM authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE UPDATE ON SEQUENCES FROM authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON TABLES FROM postgres;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON SEQUENCES FROM postgres;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL ON ROUTINES FROM postgres;

ALTER SCHEMA public OWNER TO postgres;

REVOKE USAGE ON SCHEMA public FROM PUBLIC;

REVOKE ALL ON SCHEMA public FROM pg_database_owner;

REVOKE USAGE ON SCHEMA public FROM anon;

REVOKE USAGE ON SCHEMA public FROM authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO service_role;

CREATE FUNCTION public.calculate_priority_score (
  p_issue_id uuid
)
  RETURNS integer
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_category text;
  v_created_at timestamptz;
  v_ward_id uuid;
  v_category_score integer;
  v_age_score integer;
  v_backlog_score integer;
  v_backlog_count integer;
  v_total_score integer;
begin
  select category, created_at, ward_id
  into v_category, v_created_at, v_ward_id
  from public.issues
  where id = p_issue_id;

  v_category_score := case v_category
    when 'safety' then 50
    when 'water' then 45
    when 'sanitation' then 40
    when 'electricity' then 35
    when 'roads' then 30
    when 'other' then 15
    else 20
  end;

  v_age_score := least(30, (extract(day from now() - v_created_at))::integer * 2);

  select count(*) into v_backlog_count
  from public.issues
  where ward_id = v_ward_id and status = 'pending';

  v_backlog_score := least(20, v_backlog_count);

  v_total_score := least(100, v_category_score + v_age_score + v_backlog_score);

  return v_total_score;
end;
$function$;

REVOKE ALL ON FUNCTION public.calculate_priority_score(uuid) FROM PUBLIC;

GRANT ALL ON FUNCTION public.calculate_priority_score(uuid) TO service_role;

CREATE FUNCTION public.get_ward_budget_summary (
  p_ward_id     uuid,
  p_fiscal_year text
)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_result json;
begin
  select json_build_object(
    'total_allocated', total_allocated,
    'total_utilized', total_utilized,
    'utilization_pct', case
      when total_allocated > 0
      then round((total_utilized / total_allocated * 100)::numeric, 1)
      else 0
    end
  )
  into v_result
  from public.budgets
  where ward_id = p_ward_id and fiscal_year = p_fiscal_year;

  return v_result;
end;
$function$;

GRANT ALL ON FUNCTION public.get_ward_budget_summary(uuid, text) TO service_role;

CREATE FUNCTION public.get_ward_project_summary (
  p_ward_id uuid
)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_result json;
begin
  select json_build_object(
    'total_projects', count(*),
    'completed', count(*) filter (where status = 'completed'),
    'in_progress', count(*) filter (where status = 'in_progress'),
    'avg_progress_pct', round(avg(progress)::numeric, 1),
    'total_allocated', sum(allocated_amount),
    'total_utilized', sum(utilized_amount)
  )
  into v_result
  from public.projects
  where ward_id = p_ward_id;

  return v_result;
end;
$function$;

GRANT ALL ON FUNCTION public.get_ward_project_summary(uuid) TO service_role;

CREATE FUNCTION public.get_ward_statistics (
  p_ward_id uuid
)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_result json;
begin
  select json_build_object(
    'total_issues', count(*),
    'resolved', count(*) filter (where status = 'resolved'),
    'pending', count(*) filter (where status = 'pending'),
    'avg_resolution_days', (
      select round(avg(extract(epoch from (resolved_at - created_at)) / 86400)::numeric, 1)
      from public.issues
      where ward_id = p_ward_id and status = 'resolved' and resolved_at is not null
    ),
    'priority_distribution', json_build_object(
      'critical', count(*) filter (where priority_level = 'critical'),
      'high', count(*) filter (where priority_level = 'high'),
      'medium', count(*) filter (where priority_level = 'medium'),
      'low', count(*) filter (where priority_level = 'low')
    )
  )
  into v_result
  from public.issues
  where ward_id = p_ward_id;

  return v_result;
end;
$function$;

GRANT ALL ON FUNCTION public.get_ward_statistics(uuid) TO service_role;

CREATE FUNCTION public.handle_new_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'citizen')
  );
  return new;
end;
$function$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;

GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;

CREATE FUNCTION public.is_admin()
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$function$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;

GRANT ALL ON FUNCTION public.is_admin() TO authenticated;

GRANT ALL ON FUNCTION public.is_admin() TO service_role;

CREATE FUNCTION public.log_issue_status_change()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
begin
  if old.status is distinct from new.status then
    insert into public.audit_logs (user_id, action, entity_type, entity_id, old_value, new_value)
    values (
      auth.uid(),
      'status_change',
      'issue',
      new.id,
      jsonb_build_object('status', old.status),
      jsonb_build_object('status', new.status)
    );
  end if;

  if old.resolution_notes is distinct from new.resolution_notes and new.resolution_notes is not null then
    insert into public.audit_logs (user_id, action, entity_type, entity_id, old_value, new_value)
    values (
      auth.uid(),
      'resolution_added',
      'issue',
      new.id,
      jsonb_build_object('resolution_notes', old.resolution_notes),
      jsonb_build_object('resolution_notes', new.resolution_notes)
    );
  end if;

  return new;
end;
$function$;

REVOKE ALL ON FUNCTION public.log_issue_status_change() FROM PUBLIC;

GRANT ALL ON FUNCTION public.log_issue_status_change() TO service_role;

CREATE FUNCTION public.trigger_calculate_priority()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'public'
  AS $function$
begin
  perform public.update_issue_priority(new.id);
  return new;
end;
$function$;

REVOKE ALL ON FUNCTION public.trigger_calculate_priority() FROM PUBLIC;

GRANT ALL ON FUNCTION public.trigger_calculate_priority() TO service_role;

CREATE FUNCTION public.update_issue_priority (
  p_issue_id uuid
)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
declare
  v_score integer;
  v_level text;
begin
  v_score := public.calculate_priority_score(p_issue_id);

  v_level := case
    when v_score >= 75 then 'critical'
    when v_score >= 50 then 'high'
    when v_score >= 25 then 'medium'
    else 'low'
  end;

  update public.issues
  set priority_score = v_score, priority_level = v_level
  where id = p_issue_id;
end;
$function$;

REVOKE ALL ON FUNCTION public.update_issue_priority(uuid) FROM PUBLIC;

GRANT ALL ON FUNCTION public.update_issue_priority(uuid) TO service_role;

CREATE TABLE public.audit_logs (
  id          uuid                     DEFAULT gen_random_uuid() NOT NULL,
  user_id     uuid,
  action      text                     NOT NULL,
  entity_type text                     NOT NULL,
  entity_id   uuid,
  old_value   jsonb,
  new_value   jsonb,
  created_at  timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.audit_logs
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.audit_logs
  ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);

GRANT ALL ON public.audit_logs TO service_role;

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs (user_id);

CREATE POLICY "admin insert audit logs" ON public.audit_logs
  FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "admin view audit logs" ON public.audit_logs
  FOR SELECT
  USING (public.is_admin());

CREATE TABLE public.budgets (
  id              uuid                     DEFAULT gen_random_uuid() NOT NULL,
  ward_id         uuid                     NOT NULL,
  fiscal_year     text                     NOT NULL,
  total_allocated numeric                  DEFAULT 0 NOT NULL,
  total_utilized  numeric                  DEFAULT 0 NOT NULL,
  created_at      timestamp with time zone DEFAULT now() NOT NULL,
  updated_at      timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.budgets
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.budgets
  ADD CONSTRAINT budgets_pkey PRIMARY KEY (id);

ALTER TABLE public.budgets
  ADD CONSTRAINT budgets_ward_id_fiscal_year_key UNIQUE (ward_id, fiscal_year);

GRANT ALL ON public.budgets TO service_role;

CREATE POLICY "admin delete budgets" ON public.budgets
  FOR DELETE
  USING (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "admin insert budgets" ON public.budgets
  FOR INSERT
  WITH CHECK (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "admin update budgets" ON public.budgets
  FOR UPDATE
  USING (( SELECT public.is_admin() AS is_admin))
  WITH CHECK (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "anyone can view budgets" ON public.budgets
  FOR SELECT
  USING (true);

CREATE TABLE public.issues (
  id               uuid                     DEFAULT gen_random_uuid() NOT NULL,
  reporter_id      uuid                     NOT NULL,
  ward_id          uuid,
  title            text                     NOT NULL,
  description      text,
  category         text                     NOT NULL,
  photo_url        text,
  latitude         numeric,
  longitude        numeric,
  status           text                     DEFAULT 'pending'::text NOT NULL,
  priority_score   integer                  DEFAULT 0,
  priority_level   text,
  resolution_notes text,
  resolved_by      uuid,
  resolved_at      timestamp with time zone,
  created_at       timestamp with time zone DEFAULT now() NOT NULL,
  updated_at       timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.issues
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.issues
  ADD CONSTRAINT issues_category_check CHECK (category = ANY (ARRAY['roads'::text, 'water'::text, 'sanitation'::text, 'electricity'::text, 'safety'::text, 'other'::text]));

ALTER TABLE public.issues
  ADD CONSTRAINT issues_pkey PRIMARY KEY (id);

ALTER TABLE public.issues
  ADD CONSTRAINT issues_priority_level_check CHECK (priority_level = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text]));

ALTER TABLE public.issues
  ADD CONSTRAINT issues_status_check CHECK (status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'resolved'::text, 'rejected'::text]));

GRANT ALL ON public.issues TO service_role;

CREATE INDEX idx_issues_ward ON public.issues (ward_id);

CREATE INDEX idx_issues_resolved_by ON public.issues (resolved_by);

CREATE INDEX idx_issues_status ON public.issues (status);

CREATE TRIGGER on_issue_created
  AFTER INSERT ON public.issues
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_calculate_priority();

CREATE TRIGGER on_issue_status_change
  AFTER UPDATE ON public.issues
  FOR EACH ROW
  EXECUTE FUNCTION public.log_issue_status_change();

CREATE POLICY "admin deletes issue" ON public.issues
  FOR DELETE
  USING (public.is_admin());

CREATE POLICY "admin updates any issue" ON public.issues
  FOR UPDATE
  USING (public.is_admin());

CREATE POLICY "anyone can view issues" ON public.issues
  FOR SELECT
  USING (true);

CREATE POLICY "citizen creates own issue" ON public.issues
  FOR INSERT
  WITH CHECK ((reporter_id = ( SELECT auth.uid() AS uid)));

CREATE TABLE public.profiles (
  id         uuid                     NOT NULL,
  full_name  text,
  phone      text,
  role       text                     DEFAULT 'citizen'::text NOT NULL,
  ward_id    uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.profiles
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);

ALTER TABLE public.audit_logs
  ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);

ALTER TABLE public.issues
  ADD CONSTRAINT issues_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.issues
  ADD CONSTRAINT issues_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id);

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check CHECK (role = ANY (ARRAY['citizen'::text, 'admin'::text]));

GRANT ALL ON public.profiles TO service_role;

CREATE INDEX idx_profiles_ward_id ON public.profiles (ward_id);

CREATE POLICY "insert own profile on signup" ON public.profiles
  FOR INSERT
  WITH CHECK ((id = ( SELECT auth.uid() AS uid)));

CREATE POLICY "update own profile" ON public.profiles
  FOR UPDATE
  USING ((id = ( SELECT auth.uid() AS uid)));

CREATE POLICY "view own or admin profiles" ON public.profiles
  FOR SELECT
  USING ((( SELECT public.is_admin() AS is_admin) OR (id = ( SELECT auth.uid() AS uid))));

CREATE TABLE public.projects (
  id                uuid                     DEFAULT gen_random_uuid() NOT NULL,
  ward_id           uuid,
  project_name      text                     NOT NULL,
  description       text,
  category          text,
  allocated_amount  numeric                  DEFAULT 0 NOT NULL,
  utilized_amount   numeric                  DEFAULT 0 NOT NULL,
  status            text                     DEFAULT 'planned'::text NOT NULL,
  progress          integer                  DEFAULT 0 NOT NULL,
  start_date        date,
  expected_end_date date,
  actual_end_date   date,
  created_by        uuid,
  created_at        timestamp with time zone DEFAULT now() NOT NULL,
  updated_at        timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.projects
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.projects
  ADD CONSTRAINT projects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);

ALTER TABLE public.projects
  ADD CONSTRAINT projects_pkey PRIMARY KEY (id);

ALTER TABLE public.projects
  ADD CONSTRAINT projects_progress_check CHECK (progress >= 0 AND progress <= 100);

ALTER TABLE public.projects
  ADD CONSTRAINT projects_status_check CHECK (status = ANY (ARRAY['planned'::text, 'ongoing'::text, 'completed'::text, 'delayed'::text]));

GRANT ALL ON public.projects TO service_role;

CREATE INDEX idx_projects_created_by ON public.projects (created_by);

CREATE INDEX idx_projects_ward ON public.projects (ward_id);

CREATE POLICY "admin delete projects" ON public.projects
  FOR DELETE
  USING (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "admin insert projects" ON public.projects
  FOR INSERT
  WITH CHECK (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "admin update projects" ON public.projects
  FOR UPDATE
  USING (( SELECT public.is_admin() AS is_admin))
  WITH CHECK (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "anyone can view projects" ON public.projects
  FOR SELECT
  USING (true);

CREATE TABLE public.wards (
  id         uuid                     DEFAULT gen_random_uuid() NOT NULL,
  name       text                     NOT NULL,
  city       text                     NOT NULL,
  state      text                     DEFAULT 'Karnataka'::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.wards
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.wards
  ADD CONSTRAINT wards_pkey PRIMARY KEY (id);

ALTER TABLE public.budgets
  ADD CONSTRAINT budgets_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.wards(id);

ALTER TABLE public.issues
  ADD CONSTRAINT issues_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.wards(id);

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.wards(id);

ALTER TABLE public.projects
  ADD CONSTRAINT projects_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.wards(id);

GRANT ALL ON public.wards TO service_role;

CREATE POLICY "admin delete wards" ON public.wards
  FOR DELETE
  USING (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "admin insert wards" ON public.wards
  FOR INSERT
  WITH CHECK (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "admin update wards" ON public.wards
  FOR UPDATE
  USING (( SELECT public.is_admin() AS is_admin))
  WITH CHECK (( SELECT public.is_admin() AS is_admin));

CREATE POLICY "anyone can view wards" ON public.wards
  FOR SELECT
  USING (true);
