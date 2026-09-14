INSERT INTO pharmacy (pharmacy_number, pharmacist_name, city, address) VALUES
    (1, 'Провизор А. А.', 'Москва', 'ул. Ленина, 1'),
    (2, 'Провизор Б. Б.', 'Санкт-Петербург', 'Невский проспект, 10'),
    (3, 'Провизор В. В.', 'Казань', 'ул. Баумана, 5'),
    (4, 'Провизор Г. Г.', 'Москва', 'ул. Тверская, 8');

INSERT INTO prescription
    (prescription_number, disease_code, patient_name, issue_date, doctor_name,
     validity_days, drug_name, drug_code, is_used, pharmacy_number)
VALUES
    (1, 'J06.9', 'Иванов И. И.', CURRENT_DATE, 'doctor1',
     30, 'Парацетамол', 'N02BE01', false, 1),
    (2, 'I10', 'Петров П. П.', CURRENT_DATE - INTERVAL '1 day', 'doctor1',
     10, 'Эналаприл', 'C09AA02', false, 2),
    (3, 'E11.9', 'Сидорова А. С.', CURRENT_DATE - INTERVAL '100 days', 'doctor1',
     30, 'Метформин', 'A10BA02', false, 3),
    (4, 'J45', 'Кузнецов Д. Д.', CURRENT_DATE, 'doctor1',
     7, 'Сальбутамол', 'R03AC02', true, 4),
    (5, 'K29', 'Смирнов С. С.', CURRENT_DATE, 'doctor2',
     14, 'Омепразол', 'A02BC01', false, 1),
    (6, 'M54.5', 'Волкова Е. Е.', CURRENT_DATE - INTERVAL '2 days', 'doctor2',
     5, 'Ибупрофен', 'M01AE01', false, 2),
    (7, 'A09', 'Морозов М. М.', CURRENT_DATE - INTERVAL '60 days', 'doctor2',
     30, 'Лоперамид', 'A07DA03', false, 3),
    (8, 'B34.9', 'Николаева О. О.', CURRENT_DATE - INTERVAL '1 day', 'doctor2',
     NULL, 'Парацетамол', 'N02BE01', true, 4);
