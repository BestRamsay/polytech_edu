INSERT INTO employee (fio, position, department, manages_project_code) VALUES
    ('Смирнов С. С.', 'Руководитель проектов', 'Отдел разработки', 1),
    ('Иванов И. И.', 'Руководитель проектов', 'Отдел внедрения', 2),
    ('Петров П. П.', 'Разработчик', 'Отдел разработки', NULL),
    ('Сидорова А. С.', 'Разработчик', 'Отдел разработки', NULL),
    ('Кузнецов Д. Д.', 'Аналитик', 'Отдел внедрения', NULL);

INSERT INTO task
    (project_code, project_name, task_name, executor_fio, workload_hours,
     plan_date, real_date, description, manager_approved)
VALUES
    (1, 'Разработка CRM-системы', 'Настроить CI/CD', 'Петров П. П.', 8,
     CURRENT_DATE, NULL, 'Первичная настройка пайплайна', false),
    (1, 'Разработка CRM-системы', 'Разработать модуль отчетов', 'Сидорова А. С.', 40,
     CURRENT_DATE + INTERVAL '7 days', NULL, 'Формирование отчётов', false),
    (1, 'Разработка CRM-системы', 'Покрыть авторизацию тестами', 'Петров П. П.', 24,
     CURRENT_DATE - INTERVAL '3 days', CURRENT_DATE - INTERVAL '1 day',
     'Тесты критичных сценариев', true),
    (2, 'Внедрение ERP-платформы', 'Миграция данных', 'Кузнецов Д. Д.', 56,
     CURRENT_DATE + INTERVAL '14 days', NULL, 'Перенос данных из Excel', false),
    (2, 'Внедрение ERP-платформы', 'Обучение пользователей', 'Кузнецов Д. Д.', 16,
     CURRENT_DATE - INTERVAL '10 days', NULL, 'Вводные обучения', false),
    (3, 'Модернизация ИТ-инфраструктуры', 'Обновление серверов', 'Смирнов С. С.', 12,
     CURRENT_DATE + INTERVAL '5 days', NULL, 'Плановое обновление', false);
