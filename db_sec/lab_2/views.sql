DROP VIEW IF EXISTS doctor_prescription CASCADE;
DROP VIEW IF EXISTS pharmacist_prescription CASCADE;

CREATE VIEW doctor_prescription AS
SELECT prescription_number, disease_code, patient_name, issue_date,
       doctor_name, validity_days, drug_name, drug_code, is_used,
       pharmacy_number
FROM prescription
WHERE doctor_name = current_user;

CREATE VIEW pharmacist_prescription AS
SELECT prescription_number, patient_name, issue_date, validity_days,
       drug_name, drug_code, is_used, pharmacy_number
FROM prescription;

CREATE OR REPLACE FUNCTION doctor_prescription_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
BEGIN
    IF NEW.prescription_number IS NULL THEN
        RAISE EXCEPTION 'Номер рецепта обязателен';
    END IF;
    IF NEW.doctor_name <> current_user THEN
        RAISE EXCEPTION 'Врач может выписывать только от своего имени';
    END IF;
    INSERT INTO prescription (prescription_number, disease_code,
        patient_name, issue_date, doctor_name, validity_days,
        drug_name, drug_code, is_used, pharmacy_number)
    VALUES (NEW.prescription_number, NEW.disease_code,
        NEW.patient_name, NEW.issue_date, current_user,
        NEW.validity_days, NEW.drug_name, NEW.drug_code,
        false, NEW.pharmacy_number);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER doctor_prescription_insert
INSTEAD OF INSERT ON doctor_prescription
FOR EACH ROW EXECUTE FUNCTION doctor_prescription_insert();

CREATE OR REPLACE FUNCTION doctor_prescription_update()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
BEGIN
    IF NEW.prescription_number <> OLD.prescription_number THEN
        RAISE EXCEPTION 'Номер рецепта изменять нельзя';
    END IF;
    IF NEW.disease_code <> OLD.disease_code
       OR NEW.patient_name <> OLD.patient_name
       OR NEW.issue_date <> OLD.issue_date
       OR NEW.doctor_name <> OLD.doctor_name
       OR NEW.drug_name <> OLD.drug_name
       OR NEW.drug_code <> OLD.drug_code
       OR NEW.is_used <> OLD.is_used
       OR NEW.pharmacy_number <> OLD.pharmacy_number THEN
        RAISE EXCEPTION 'Врач может изменять только срок действия';
    END IF;
    IF NEW.validity_days <> OLD.validity_days THEN
        UPDATE prescription SET validity_days = NEW.validity_days
        WHERE prescription_number = OLD.prescription_number
          AND doctor_name = current_user;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER doctor_prescription_update
INSTEAD OF UPDATE ON doctor_prescription
FOR EACH ROW EXECUTE FUNCTION doctor_prescription_update();

CREATE OR REPLACE FUNCTION pharmacist_prescription_update()
RETURNS TRIGGER LANGUAGE plpgsql AS
$$
BEGIN
    IF NEW.prescription_number <> OLD.prescription_number THEN
        RAISE EXCEPTION 'Номер рецепта изменять нельзя';
    END IF;
    IF NEW.patient_name <> OLD.patient_name
       OR NEW.issue_date <> OLD.issue_date
       OR NEW.validity_days <> OLD.validity_days
       OR NEW.drug_name <> OLD.drug_name
       OR NEW.drug_code <> OLD.drug_code THEN
        RAISE EXCEPTION 'Провизор может изменять только признак использования и номер аптеки';
    END IF;
    IF NEW.is_used = false AND OLD.is_used = true THEN
        RAISE EXCEPTION 'Признак использования нельзя вернуть в false';
    END IF;
    IF OLD.is_used = true THEN
        RAISE EXCEPTION 'Использованный рецепт нельзя изменять';
    END IF;
    IF NEW.is_used <> OLD.is_used
       OR NEW.pharmacy_number <> OLD.pharmacy_number THEN
        UPDATE prescription
        SET is_used = NEW.is_used,
            pharmacy_number = NEW.pharmacy_number
        WHERE prescription_number = OLD.prescription_number
          AND is_used = false
          AND (validity_days IS NULL
               OR CURRENT_DATE <= issue_date + validity_days);
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER pharmacist_prescription_update
INSTEAD OF UPDATE ON pharmacist_prescription
FOR EACH ROW EXECUTE FUNCTION pharmacist_prescription_update();
