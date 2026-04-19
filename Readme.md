# dbops-project
Исходный репозиторий для выполнения проекта дисциплины "DBOps"

## SQL-запросы

### Создание базы данных и пользователя

```sql
DROP DATABASE IF EXISTS store;
DROP ROLE IF EXISTS store_user;

CREATE ROLE store_user WITH LOGIN PASSWORD 'store_password';
CREATE DATABASE store OWNER store_user;

GRANT ALL PRIVILEGES ON DATABASE store TO store_user;
```

### Выдача прав пользователю в базе `store`

```sql
GRANT ALL ON SCHEMA public TO store_user;
ALTER SCHEMA public OWNER TO store_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO store_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO store_user;
```
