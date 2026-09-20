DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'doctor_role') THEN
        CREATE ROLE doctor_role NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pharmacist_role') THEN
        CREATE ROLE pharmacist_role NOLOGIN;
    END IF;
END$$;

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
END$$;

GRANT doctor_role TO doctor1;
GRANT doctor_role TO doctor2;
GRANT pharmacist_role TO pharmacist1;
GRANT pharmacist_role TO pharmacist2;

GRANT USAGE ON SCHEMA public TO doctor_role, pharmacist_role;

REVOKE ALL PRIVILEGES ON prescription FROM doctor_role, pharmacist_role;
REVOKE ALL PRIVILEGES ON pharmacy FROM doctor_role, pharmacist_role;
REVOKE ALL PRIVILEGES ON log_prescription FROM doctor_role, pharmacist_role;

GRANT SELECT, INSERT, UPDATE ON doctor_prescription TO doctor_role;
GRANT SELECT, UPDATE ON pharmacist_prescription TO pharmacist_role;
