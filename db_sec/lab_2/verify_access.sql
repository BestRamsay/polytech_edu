SELECT 'doctor1: видимые рецепты' AS test;
SET ROLE doctor1;
SELECT prescription_number, disease_code, patient_name, doctor_name, validity_days
FROM doctor_prescription
ORDER BY prescription_number;

SELECT 'doctor1: попытка изменить чужой рецепт' AS test;
UPDATE doctor_prescription
SET validity_days = 100
WHERE prescription_number = 5;

SELECT 'doctor1: изменение своего рецепта' AS test;
UPDATE doctor_prescription
SET validity_days = 45
WHERE prescription_number = 1;

SELECT 'doctor1: добавление рецепта' AS test;
INSERT INTO doctor_prescription
    (prescription_number, disease_code, patient_name, issue_date, doctor_name,
     validity_days, drug_name, drug_code, is_used, pharmacy_number)
VALUES
    (20, 'J06.9', 'Тестов Т. Т.', CURRENT_DATE, 'doctor1',
     14, 'Парацетамол', 'N02BE01', false, 1);

SELECT 'doctor1: попытка добавить от имени другого врача' AS test;
INSERT INTO doctor_prescription
    (prescription_number, disease_code, patient_name, issue_date, doctor_name,
     validity_days, drug_name, drug_code, is_used, pharmacy_number)
VALUES
    (21, 'J06.9', 'Тестов Т. Т.', CURRENT_DATE, 'doctor2',
     14, 'Парацетамол', 'N02BE01', false, 1);

RESET ROLE;

SELECT 'pharmacist1: видимые поля' AS test;
SET ROLE pharmacist1;
SELECT prescription_number, issue_date, validity_days, drug_name, drug_code,
       is_used, pharmacy_number
FROM pharmacist_prescription
ORDER BY prescription_number;

SELECT 'pharmacist1: попытка прочитать закрытый столбец' AS test;
SELECT disease_code FROM pharmacist_prescription;

SELECT 'pharmacist1: обновление действующего рецепта' AS test;
UPDATE pharmacist_prescription
SET pharmacy_number = 2
WHERE prescription_number = 1;

SELECT 'pharmacist1: попытка отметить использованный рецепт' AS test;
UPDATE pharmacist_prescription
SET is_used = true
WHERE prescription_number = 4;

SELECT 'pharmacist1: попытка изменить просроченный рецепт' AS test;
UPDATE pharmacist_prescription
SET pharmacy_number = 3
WHERE prescription_number = 7;

SELECT 'pharmacist1: попытка вернуть признак использования' AS test;
UPDATE pharmacist_prescription
SET is_used = false
WHERE prescription_number = 4;

SELECT 'pharmacist1: попытка вставить рецепт' AS test;
INSERT INTO pharmacist_prescription
    (prescription_number, patient_name, issue_date, validity_days,
     drug_name, drug_code, is_used, pharmacy_number)
VALUES
    (22, 'Тестов Т. Т.', CURRENT_DATE, 14,
     'Парацетамол', 'N02BE01', false, 1);

SELECT 'pharmacist1: попытка удалить рецепт' AS test;
DELETE FROM pharmacist_prescription
WHERE prescription_number = 1;

RESET ROLE;

SELECT 'doctor1: попытка удалить рецепт' AS test;
DELETE FROM doctor_prescription
WHERE prescription_number = 1;

SELECT 'прямое чтение таблицы запрещено' AS test;
SELECT * FROM prescription;

SELECT 'прямая вставка запрещена' AS test;
INSERT INTO prescription
    (prescription_number, disease_code, patient_name, issue_date, doctor_name,
     validity_days, drug_name, drug_code, is_used, pharmacy_number)
VALUES
    (23, 'J06.9', 'Тестов Т. Т.', CURRENT_DATE, 'doctor1',
     14, 'Парацетамол', 'N02BE01', false, 1);

RESET ROLE;

SELECT 'аудит: последние записи' AS test;
SELECT log_id, username, action, prescription_number, changed_on
FROM log_prescription
ORDER BY log_id DESC
LIMIT 20;
