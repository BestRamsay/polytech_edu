DROP TABLE IF EXISTS prescription CASCADE;
DROP TABLE IF EXISTS pharmacy CASCADE;

CREATE TABLE pharmacy
(
    pharmacy_number int PRIMARY KEY NOT NULL,
    pharmacist_name varchar(100) NOT NULL,
    city varchar(100) NOT NULL,
    address varchar(200) NOT NULL,
    CONSTRAINT uq_pharmacy_pharmacist UNIQUE (pharmacist_name),
    CONSTRAINT uq_pharmacy_city_address UNIQUE (city, address)   
);

CREATE TABLE prescription
(
    prescription_number int PRIMARY KEY NOT NULL,
    disease_code varchar(20) NOT NULL,
    patient_name varchar(100) NOT NULL,
    issue_date date NOT NULL,
    doctor_name varchar(100) NOT NULL,
    validity_days int,
    drug_name varchar(200) NOT NULL,
    drug_code varchar(20) NOT NULL,
    is_used boolean NOT NULL DEFAULT false,
    pharmacy_number int NOT NULL,
    CONSTRAINT uq_prescription_patient_issue UNIQUE (patient_name, issue_date),
    CONSTRAINT chk_prescription_validity CHECK (validity_days IS NULL OR validity_days > 0),
    CONSTRAINT fk_prescription_pharmacy FOREIGN KEY (pharmacy_number)
        REFERENCES pharmacy (pharmacy_number)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE pharmacy IS 'Аптеки';
COMMENT ON TABLE prescription IS 'Рецепты';
