#!/bin/sh
set -eu

# 1. Membuat Role/User dan Database 'sre'
psql --username "$POSTGRES_USER" --dbname postgres --set ON_ERROR_STOP=1 \
  --set full_access_user="sre" \
  --set full_access_password="$POSTGRES_APP_PASSWORD" \
  --set readonly_user="sre_read" \
  --set readonly_password="$POSTGRES_READONLY_PASSWORD" <<'SQL'
CREATE ROLE :"full_access_user" LOGIN PASSWORD :'full_access_password';
CREATE ROLE :"readonly_user" LOGIN PASSWORD :'readonly_password';

CREATE DATABASE sre OWNER :"full_access_user";
SQL

# 2. Mengatur Hak Akses di dalam database 'sre'
psql --username "$POSTGRES_USER" --dbname sre --set ON_ERROR_STOP=1 \
  --set full_access_user="sre" \
  --set readonly_user="sre_read" <<'SQL'
-- Memberikan hak akses penuh ke 'sre' dan 'postgres'
GRANT ALL PRIVILEGES ON DATABASE sre TO :"full_access_user";
GRANT ALL PRIVILEGES ON DATABASE sre TO postgres;
GRANT USAGE, CREATE ON SCHEMA public TO :"full_access_user";
GRANT USAGE, CREATE ON SCHEMA public TO postgres;

-- Memberikan hak hanya BACA (Read-Only) ke 'sre_read'
GRANT CONNECT ON DATABASE sre TO :"readonly_user";
GRANT USAGE ON SCHEMA public TO :"readonly_user";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO :"readonly_user";

-- Otomatisasi agar tabel baru yang dibuat nanti bisa langsung dibaca 'sre_read'
ALTER DEFAULT PRIVILEGES FOR ROLE :"full_access_user" IN SCHEMA public
  GRANT SELECT ON TABLES TO :"readonly_user";
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT SELECT ON TABLES TO :"readonly_user";
SQL