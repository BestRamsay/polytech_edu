DROP TABLE IF EXISTS task CASCADE;
DROP TABLE IF EXISTS employee CASCADE;

CREATE TABLE employee
(
    fio varchar(100) PRIMARY KEY NOT NULL,
    position varchar(100) NOT NULL,
    department varchar(200) NOT NULL,
    manages_project_code int,
    CONSTRAINT uq_employee_manages_project UNIQUE (manages_project_code)
);

CREATE TABLE task
(
    project_code int NOT NULL,
    project_name varchar(200) NOT NULL,
    task_name varchar(200) NOT NULL,
    executor_fio varchar(100) NOT NULL,
    workload_hours int NOT NULL,
    plan_date date NOT NULL,
    real_date date,
    description varchar(500),
    manager_approved boolean NOT NULL DEFAULT false,
    CONSTRAINT pk_task PRIMARY KEY (project_code, task_name),
    CONSTRAINT uq_task_ak1 UNIQUE (project_name, task_name),
    CONSTRAINT chk_task_workload CHECK (workload_hours > 0),
    CONSTRAINT fk_task_executor FOREIGN KEY (executor_fio)
        REFERENCES employee (fio)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMENT ON TABLE employee IS 'Сотрудники';
COMMENT ON TABLE task IS 'Задачи';
