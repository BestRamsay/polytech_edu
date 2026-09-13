DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'employee_role') THEN
        CREATE ROLE employee_role NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'manager_role') THEN
        CREATE ROLE manager_role NOLOGIN;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'employee1') THEN
        CREATE ROLE employee1 LOGIN PASSWORD 'employee1';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'employee2') THEN
        CREATE ROLE employee2 LOGIN PASSWORD 'employee2';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'manager1') THEN
        CREATE ROLE manager1 LOGIN PASSWORD 'manager1';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'manager2') THEN
        CREATE ROLE manager2 LOGIN PASSWORD 'manager2';
    END IF;
END
$$;

GRANT manager_role TO manager1;
GRANT manager_role TO manager2;
GRANT employee_role TO employee1;
GRANT employee_role TO employee2;

GRANT USAGE ON SCHEMA public TO employee_role, manager_role;

GRANT SELECT (fio, manages_project_code) ON employee TO employee_role, manager_role;

GRANT SELECT (project_name, task_name, executor_fio, workload_hours, plan_date, real_date, description)
    ON task TO employee_role;
GRANT UPDATE (real_date) ON task TO employee_role;

GRANT SELECT (project_code, project_name, task_name, executor_fio, workload_hours,
              plan_date, real_date, description, manager_approved)
    ON task TO manager_role;
GRANT UPDATE (manager_approved) ON task TO manager_role;
GRANT UPDATE (real_date) ON task TO manager_role;

ALTER TABLE task ENABLE ROW LEVEL SECURITY;
ALTER TABLE task FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS employee_select_policy ON task;
CREATE POLICY employee_select_policy ON task
    FOR SELECT TO employee_role
    USING (
        EXISTS (
            SELECT 1 FROM employee e
            WHERE e.fio = current_setting('app.current_user')
              AND (e.manages_project_code = task.project_code
                   OR e.fio = task.executor_fio)
        )
    );

DROP POLICY IF EXISTS employee_update_policy ON task;
CREATE POLICY employee_update_policy ON task
    FOR UPDATE TO employee_role
    USING (
        EXISTS (
            SELECT 1 FROM employee e
            WHERE e.fio = current_setting('app.current_user')
              AND (e.manages_project_code = task.project_code
                   OR e.fio = task.executor_fio)
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM employee e
            WHERE e.fio = current_setting('app.current_user')
              AND (e.manages_project_code = task.project_code
                   OR e.fio = task.executor_fio)
        )
    );

DROP POLICY IF EXISTS manager_select_policy ON task;
CREATE POLICY manager_select_policy ON task
    FOR SELECT TO manager_role
    USING (
        EXISTS (
            SELECT 1 FROM employee e
            WHERE e.fio = current_setting('app.current_user')
              AND e.manages_project_code = task.project_code
        )
    );

DROP POLICY IF EXISTS manager_update_policy ON task;
CREATE POLICY manager_update_policy ON task
    FOR UPDATE TO manager_role
    USING (
        EXISTS (
            SELECT 1 FROM employee e
            WHERE e.fio = current_setting('app.current_user')
              AND e.manages_project_code = task.project_code
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM employee e
            WHERE e.fio = current_setting('app.current_user')
              AND e.manages_project_code = task.project_code
        )
    );
