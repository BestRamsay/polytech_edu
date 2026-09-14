DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'doctor_role') THEN
        CREATE ROLE doctor_role NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pharmacist_role') THEN
        CREATE ROLE pharmacist_role NOLOGIN;
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'doctor1') THEN
        CREATE ROLE doctor1 LOGIN PASSWORD 'doctor1';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'doctor2') THEN
        CREATE ROLE doctor2 LOGIN PASSWORD 'doctor2';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pharmacist1') THEN
        CREATE ROLE pharmacist1 LOGIN PASSWORD 'pharmacist1';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pharmacist2') THEN
        CREATE ROLE pharmacist2 LOGIN PASSWORD 'pharmacist2';
    END IF;
END
$$;

GRANT doctor_role TO doctor1;
GRANT doctor_role TO doctor2;
GRANT pharmacist_role TO pharmacist1;
GRANT pharmacist_role TO pharmacist2;

GRANT USAGE ON SCHEMA public TO doctor_role, pharmacist_role;

GRANT SELECT ON pharmacy TO pharmacist_role;

GRANT SELECT ON prescription TO doctor_role;
GRANT INSERT ON prescription TO doctor_role;
GRANT UPDATE (validity_days) ON prescription TO doctor_role;

GRANT SELECT (prescription_number, issue_date, doctor_name, validity_days,
              drug_name, drug_code, is_used, pharmacy_number)
    ON prescription TO pharmacist_role;
GRANT UPDATE (is_used, pharmacy_number) ON prescription TO pharmacist_role;

ALTER TABLE prescription ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS doctor_select_policy ON prescription;
CREATE POLICY doctor_select_policy ON prescription
    FOR SELECT TO doctor_role
    USING (true);

DROP POLICY IF EXISTS doctor_insert_policy ON prescription;
CREATE POLICY doctor_insert_policy ON prescription
    FOR INSERT TO doctor_role
    WITH CHECK (doctor_name = current_user);

DROP POLICY IF EXISTS doctor_update_policy ON prescription;
CREATE POLICY doctor_update_policy ON prescription
    FOR UPDATE TO doctor_role
    USING (doctor_name = current_user)
    WITH CHECK (doctor_name = current_user);

DROP POLICY IF EXISTS pharmacist_select_policy ON prescription;
CREATE POLICY pharmacist_select_policy ON prescription
    FOR SELECT TO pharmacist_role
    USING (true);

DROP POLICY IF EXISTS pharmacist_update_policy ON prescription;
CREATE POLICY pharmacist_update_policy ON prescription
    FOR UPDATE TO pharmacist_role
    USING (
        is_used = false
        AND (validity_days IS NULL OR CURRENT_DATE <= issue_date + validity_days)
    )
    WITH CHECK (
        is_used = false
        AND (validity_days IS NULL OR CURRENT_DATE <= issue_date + validity_days)
    );
