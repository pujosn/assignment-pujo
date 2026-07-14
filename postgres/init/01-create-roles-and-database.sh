#!/bin/sh
set -eu

psql --username "$POSTGRES_USER" --dbname postgres --set ON_ERROR_STOP=1 \
  --set full_access_user="$POSTGRES_APP_USER" \
  --set full_access_password="$POSTGRES_APP_PASSWORD" \
  --set readonly_user="$POSTGRES_READONLY_USER" \
  --set readonly_password="$POSTGRES_READONLY_PASSWORD" <<'SQL'
CREATE ROLE :"full_access_user" LOGIN PASSWORD :'full_access_password';
CREATE ROLE :"readonly_user" LOGIN PASSWORD :'readonly_password';
CREATE DATABASE sre OWNER :"full_access_user";
SQL


psql --username "$POSTGRES_USER" --dbname sre --set ON_ERROR_STOP=1 \
  --set full_access_user="$POSTGRES_APP_USER" \
  --set readonly_user="$POSTGRES_READONLY_USER" <<'SQL'
GRANT ALL PRIVILEGES ON DATABASE sre TO :"full_access_user";
GRANT USAGE, CREATE ON SCHEMA public TO :"full_access_user";

GRANT CONNECT ON DATABASE sre TO :"readonly_user";
GRANT USAGE ON SCHEMA public TO :"readonly_user";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO :"readonly_user";
ALTER DEFAULT PRIVILEGES FOR ROLE :"full_access_user" IN SCHEMA public
  GRANT SELECT ON TABLES TO :"readonly_user";
SQL
