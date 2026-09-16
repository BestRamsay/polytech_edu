REVOKE ALL PRIVILEGES ON prescription
FROM doctor_role;

GRANT SELECT ON prescription TO doctor_role;
GRANT INSERT ON prescription TO doctor_role;
GRANT UPDATE (validity_days) ON prescription TO doctor_role;

ALTER TABLE prescription ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS doctor_select_policy ON prescription;
DROP POLICY IF EXISTS doctor_insert_policy ON prescription;
DROP POLICY IF EXISTS doctor_update_policy ON prescription;

CREATE POLICY doctor_select_policy
ON prescription
FOR SELECT
TO doctor_role
USING (
    doctor_name = current_user
);

CREATE POLICY doctor_insert_policy
ON prescription
FOR INSERT
TO doctor_role
WITH CHECK (
    doctor_name = current_user
);

CREATE POLICY doctor_update_policy
ON prescription
FOR UPDATE
TO doctor_role
USING (
    doctor_name = current_user
)
WITH CHECK (
    doctor_name = current_user
);

REVOKE ALL PRIVILEGES ON prescription
FROM pharmacist_role;

GRANT SELECT (
    prescription_number,
    patient_name,
    issue_date,
    validity_days,
    drug_name,
    drug_code,
    is_used,
    pharmacy_number
) ON prescription
TO pharmacist_role;

GRANT UPDATE (
    is_used,
    pharmacy_number
) ON prescription
TO pharmacist_role;

ALTER TABLE prescription ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pharmacist_select_policy ON prescription;
DROP POLICY IF EXISTS pharmacist_update_policy ON prescription;

CREATE POLICY pharmacist_select_policy
ON prescription
FOR SELECT
TO pharmacist_role
USING (true);

CREATE POLICY pharmacist_update_policy
ON prescription
FOR UPDATE
TO pharmacist_role
USING (
    is_used = false
    AND (
        validity_days IS NULL
        OR CURRENT_DATE <= issue_date + validity_days
    )
)
WITH CHECK (true);
