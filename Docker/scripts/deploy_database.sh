#!/bin/bash

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

# Definir DATABASE_URL com o valor de DATABASE_CONNECTION_URI
export DATABASE_URL=$DATABASE_CONNECTION_URI

if [[ "$DATABASE_PROVIDER" == "postgresql" || "$DATABASE_PROVIDER" == "mysql" ]]; then
    echo "Deploying migrations for $DATABASE_PROVIDER"
    echo "Database URL: $DATABASE_URL"
    npm run db:deploy
    if [ $? -ne 0 ]; then
        echo "Migration failed"
        exit 1
    else
        echo "Migration succeeded"
    fi
    npm run db:generate
    if [ $? -ne 0 ]; then
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi
