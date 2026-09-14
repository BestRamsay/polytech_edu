SELECT 'manager1: свой проект полностью' AS test;
SET ROLE manager1;
SET app."current_user" = 'Смирнов С. С.';
SELECT project_code, project_name, task_name, executor_fio, manager_approved
FROM task
ORDER BY project_code, task_name;

SELECT 'manager1: чужой проект не виден' AS test;
SELECT project_code, task_name FROM task
WHERE project_code = 2
ORDER BY task_name;

SELECT 'manager1: отметить задачу своего проекта' AS test;
UPDATE task
SET manager_approved = true
WHERE project_code = 1 AND task_name = 'Разработать модуль отчетов';

SELECT 'manager1: нельзя отметить чужой проект' AS test;
UPDATE task
SET manager_approved = true
WHERE project_code = 2 AND task_name = 'Миграция данных';

RESET ROLE;

SELECT 'employee1: проекты, на которых работает' AS test;
SET ROLE employee1;
SET app."current_user" = 'Петров П. П.';
SELECT DISTINCT project_name FROM task
ORDER BY project_name;

SELECT 'employee1: задачи без закрытых полей' AS test;
SELECT project_name, task_name, executor_fio, workload_hours, plan_date,
       real_date, description
FROM task
ORDER BY project_name, task_name;

SELECT 'employee1: изменение чужой реальной даты запрещено' AS test;
UPDATE task
SET real_date = CURRENT_DATE
WHERE project_name = 'Внедрение ERP-платформы' AND task_name = 'Миграция данных';

SELECT 'employee1: изменение своей реальной даты разрешено' AS test;
UPDATE task
SET real_date = CURRENT_DATE
WHERE project_name = 'Разработка CRM-системы' AND task_name = 'Настроить CI/CD';

SELECT 'employee1: код проекта и отметка руководителя не видны' AS test;
SELECT project_code, manager_approved FROM task;

RESET ROLE;
