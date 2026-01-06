#!/bin/bash

# Exit immediately if a command exits with a non zero status
set -e
# Treat unset variables as an error when substituting
set -u

function create_databases() {
    local db=$1
    local user=$2
    local pass=$3
    
    echo "Creating Database: '$db' | User: '$user' | Password: '$pass'"
    
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        -- Create user if it doesn't exist (prevents errors if one user owns multiple DBs)
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$user') THEN
                CREATE USER $user WITH ENCRYPTED PASSWORD '$pass';
            END IF;
        END
        \$\$;
        
        CREATE DATABASE $db;
        GRANT ALL PRIVILEGES ON DATABASE $db TO $user;
EOSQL
}

# POSTGRES_MULTIPLE_DATABASES=db1,db2:usr2,db3:pass3,db4:usr4:pass4
if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    for entry in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        # Parse the string
        db_name=$(echo $entry | awk -F":" '{print $1}')
        db_user=$(echo $entry | awk -F":" '{print $2}')
        db_pass=$(echo $entry | awk -F":" '{print $3}')

        # Fallback for User
        if [[ -z "$db_user" ]]; then
            db_user=$POSTGRES_USER
        fi

        # Fallback for Password
        if [[ -z "$db_pass" ]]; then
            db_pass=$POSTGRES_PASSWORD
        fi

        create_databases "$db_name" "$db_user" "$db_pass"
    done
    echo "Multiple databases created!"
fi
