#!/bin/bash

SLEEPING=$1 # 0 = no, 1 = yes

ROOTDIR=$(dirname "$0")
if [ "$ROOTDIR" = "." ]; then
    ROOTDIR=$(pwd)
fi
echo "1. ROOTDIR:$ROOTDIR"

sleeping () {
    echo "2. sleeping $SLEEPING"
    if [ "$SLEEPING." == "1." ]; then
        while true; do
            echo "Sleeping... forever."
            sleep 999999999
        done
    else
        echo "Cannot sleep must exit."
        exit 1
    fi
}

apt-get update -y && apt-get upgrade -y

export DEBIAN_FRONTEND=noninteractive

TZ=$(echo $TZ)

if [ "$TZ" = "" ]; then
    TZ=America/Denver
fi

export TZ=$TZ

apt-get install -y tzdata

apt-get update -y
apt-get install net-tools -y
apt-get install iputils-ping -y
apt-get install nano -y

apt-get install -y apt-utils && apt-get install -y curl

POSTGRESPASSWORD=$(echo $POSTGRES_PASSWORD)
if [ -z "$POSTGRESPASSWORD" ]; then
    echo "Undefined POSTGRESPASSWORD:$POSTGRESPASSWORD, cannot continue."
    sleeping
fi

export PGPASSWORD='$POSTGRESPASSWORD'

POSTGRES_STATUS=$(apt-get install postgresql postgresql-contrib -y | grep -v "You can now start the database server")

if [ -z "$POSTGRES_STATUS" ]; then
    echo "POSTGRES_STATUS:$POSTGRES_STATUS, cannot continue."
    sleeping
fi

USERNAME=postgres

getent passwd $USERNAME > /dev/null 2&>1
if [ $? -eq 0 ]; then
    echo "User USERNAME:$USERNAME exists so setting the password."
    echo -e "0rang3z3bra\n0rang3z3bra" | (passwd $USERNAME)
else
    echo "User USERNAME:$USERNAME does not exist so creating the user."
    adduser --disabled-password --gecos GECOS --shell /bin/bash --home /home/$USERNAME $USERNAME
fi

su - $USERNAME

sleep 10
pg_ctlcluster 12 main start

sleep 10
PSQL=$(which psql)

if [ -z "$PSQL" ]; then
    echo "Missing PSQL:$PSQL, cannot continue."
    sleeping
fi

POSTGRESUSER=$(echo $POSTGRES_USER)

if [ -z "$POSTGRESUSER" ]; then
    echo "Undefined POSTGRESUSER:$POSTGRESUSER, cannot continue."
    sleeping
fi

echo "2. Creating POSTGRESUSER:$POSTGRESUSER"
createuser -s -i -d -r -l -w $POSTGRESUSER

PGTEST1=$(psql -U $POSTGRESUSER -d postgres -c "select 1" | grep -v "1 row")

if [ -z "$PGTEST1" ]; then
    echo "PGTEST1:$PGTEST1, cannot continue."
    sleeping
fi

PGTEST2=$(netstat -tulpn | grep 5432 | grep LISTEN)

if [ -z "$PGTEST2" ]; then
    echo "PGTEST2:$PGTEST2, cannot continue."
    sleeping
fi

#psql -c "ALTER ROLE $POSTGRESUSER WITH PASSWORD '$POSTGRESPASSWORD';"

echo "Done."
sleeping


