#!/bin/bash
#
#   POSTGRES_MULTIPLE_DATABASES="db1,db2:user2:pass2,db3:user3:pass3"
#
#   db            -> owned by $POSTGRES_USER (no new role created)
#   db:user       -> ERROR unless user == $POSTGRES_USER (new roles need a password)
#   db:user:pass  -> pass may contain ':' but not ','

set -euo pipefail

create_database() {
    local db=$1 user=$2 pass=$3

    echo "Creating database '$db' (owner: '$user')"

    DB_NAME="$db" DB_USER="$user" DB_PASS="$pass" \
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-'EOSQL'
		\getenv db_name DB_NAME
		\getenv db_user DB_USER
		\getenv db_pass DB_PASS

		SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'db_user', :'db_pass')
		WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'db_user')
		\gexec

		SELECT format('CREATE DATABASE %I OWNER %I', :'db_name', :'db_user')
		WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'db_name')
		\gexec

		SELECT format('REVOKE ALL ON DATABASE %I FROM PUBLIC', :'db_name')
		\gexec
EOSQL
}

if [[ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]]; then
    IFS=',' read -ra entries <<< "$POSTGRES_MULTIPLE_DATABASES"

    i=0
    for entry in "${entries[@]}"; do
        i=$((i + 1))
        IFS=':' read -r db user pass <<< "$entry"

        if [[ -z "$db" ]]; then
            echo "ERROR: entry #$i in POSTGRES_MULTIPLE_DATABASES has an empty database name" >&2
            exit 1
        fi
        if [[ -n "$user" && "$user" != "$POSTGRES_USER" && -z "${pass:-}" ]]; then
            echo "ERROR: entry #$i ('$db'): role '$user' needs an explicit password (db:user:pass)" >&2
            exit 1
        fi
    done

    for entry in "${entries[@]}"; do
        IFS=':' read -r db user pass <<< "$entry"
        create_database "$db" "${user:-$POSTGRES_USER}" "${pass:-}"
    done

    echo "Multiple databases created!"
fi
