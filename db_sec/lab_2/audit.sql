DROP TABLE IF EXISTS log_prescription CASCADE;

CREATE TABLE log_prescription
(
    log_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username varchar(100) NOT NULL,
    action varchar(10) NOT NULL
        CHECK (action IN ('insert', 'update', 'delete')),
    prescription_number int NOT NULL,
    old_values text,
    new_values text,
    changed_on timestamp(6) NOT NULL DEFAULT current_timestamp
);

COMMENT ON TABLE log_prescription IS 'Аудит манипуляций с рецептами';

CREATE OR REPLACE FUNCTION audit_prescription()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO log_prescription
            (username, action, prescription_number, old_values, new_values)
        VALUES (current_user, 'delete', OLD.prescription_number,
            format('disease_code=%s; patient_name=%s; issue_date=%s; '
                   'doctor_name=%s; validity_days=%s; drug_name=%s; '
                   'drug_code=%s; is_used=%s; pharmacy_number=%s',
                OLD.disease_code, OLD.patient_name, OLD.issue_date,
                OLD.doctor_name, OLD.validity_days, OLD.drug_name,
                OLD.drug_code, OLD.is_used, OLD.pharmacy_number),
            NULL);
        RETURN OLD;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO log_prescription
            (username, action, prescription_number, old_values, new_values)
        VALUES (current_user, 'insert', NEW.prescription_number,
            NULL,
            format('disease_code=%s; patient_name=%s; issue_date=%s; '
                   'doctor_name=%s; validity_days=%s; drug_name=%s; '
                   'drug_code=%s; is_used=%s; pharmacy_number=%s',
                NEW.disease_code, NEW.patient_name, NEW.issue_date,
                NEW.doctor_name, NEW.validity_days, NEW.drug_name,
                NEW.drug_code, NEW.is_used, NEW.pharmacy_number));
        RETURN NEW;
    ELSE
        INSERT INTO log_prescription
            (username, action, prescription_number, old_values, new_values)
        VALUES (current_user, 'update', NEW.prescription_number,
            format('disease_code=%s; patient_name=%s; issue_date=%s; '
                   'doctor_name=%s; validity_days=%s; drug_name=%s; '
                   'drug_code=%s; is_used=%s; pharmacy_number=%s',
                OLD.disease_code, OLD.patient_name, OLD.issue_date,
                OLD.doctor_name, OLD.validity_days, OLD.drug_name,
                OLD.drug_code, OLD.is_used, OLD.pharmacy_number),
            format('disease_code=%s; patient_name=%s; issue_date=%s; '
                   'doctor_name=%s; validity_days=%s; drug_name=%s; '
                   'drug_code=%s; is_used=%s; pharmacy_number=%s',
                NEW.disease_code, NEW.patient_name, NEW.issue_date,
                NEW.doctor_name, NEW.validity_days, NEW.drug_name,
                NEW.drug_code, NEW.is_used, NEW.pharmacy_number));
        RETURN NEW;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS audit_prescription ON prescription;
CREATE TRIGGER audit_prescription
AFTER INSERT OR UPDATE OR DELETE ON prescription
FOR EACH ROW EXECUTE FUNCTION audit_prescription();

CREATE INDEX idx_log_prescription_number
ON log_prescription (prescription_number);

CREATE INDEX idx_log_prescription_changed_on
ON log_prescription (changed_on DESC);
