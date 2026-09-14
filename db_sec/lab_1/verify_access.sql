SELECT 'doctor1: видимые рецепты' AS test;
SET ROLE doctor1;
SELECT prescription_number, disease_code, patient_name, doctor_name, validity_days
FROM prescription
ORDER BY prescription_number;

SELECT 'doctor1: попытка обновить чужой рецепт' AS test;
UPDATE prescription
SET validity_days = 100
WHERE prescription_number = 5;

SELECT 'doctor1: обновление своего рецепта' AS test;
UPDATE prescription
SET validity_days = 45
WHERE prescription_number = 1;

RESET ROLE;

SELECT 'pharmacist1: видимые поля' AS test;
SET ROLE pharmacist1;
SELECT prescription_number, issue_date, validity_days, drug_name, drug_code,
       is_used, pharmacy_number
FROM prescription
ORDER BY prescription_number;

SELECT 'pharmacist1: обновление действующего рецепта' AS test;
UPDATE prescription
SET pharmacy_number = 2
WHERE prescription_number = 1;

SELECT 'pharmacist1: попытка обновить использованный рецепт' AS test;
UPDATE prescription
SET is_used = false
WHERE prescription_number = 4;

SELECT 'pharmacist1: попытка прочитать закрытый столбец' AS test;
SELECT disease_code FROM prescription;
