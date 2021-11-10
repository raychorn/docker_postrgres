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

move_file () {
    local resp='0'
    if [ -f "$1" ]; then
        resp='1'
        if [ -f "$2" ]; then
            mv -f "$1" "$2"
            chown postgres:postgres $2
            resp='2'
        else
            resp='-2'
        fi
    else
        resp='-1'
    fi
    echo "$resp"
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

POSTGRESUSER=$(echo $POSTGRES_USER)
if [ -z "$POSTGRESUSER" ]; then
    echo "Undefined POSTGRESUSER:$POSTGRESUSER, cannot continue."
    sleeping
fi

echo "POSTGRESUSER:$POSTGRESUSER"
echo "POSTGRESPASSWORD:$POSTGRESPASSWORD"
echo "POSTGRES_DB:$POSTGRES_DB"

USERNAME=postgres

if id "$USERNAME" &>/dev/null; then
    echo "User USERNAME:$USERNAME exists so setting the password."
    echo -e "$PGPASSWORD\n$PGPASSWORD" | (passwd $USERNAME)
else
    echo "User USERNAME:$USERNAME does not exist so creating the user."
    adduser --disabled-password --gecos GECOS --shell /bin/bash --home /home/$USERNAME $USERNAME
fi

##### BEGIN: postgresql.conf
SRC=/postgresql.conf
DST=/etc/postgresql/12/main$SRC

move_file $SRC $DST
##### END!!! postgresql.conf

##### BEGIN: pg_hba.conf
SRC=/pg_hba.conf
DST=/etc/postgresql/12/main$SRC

move_file $SRC $DST
##### END!!! pg_hba.conf

echo "Starting postgresql"
service postgresql start

sleep 10
PSQL=$(which psql)

if [ -z "$PSQL" ]; then
    echo "Missing PSQL:$PSQL, cannot continue."
    sleeping
fi

#echo "Time to debug."
#sleeping

echo "2. Creating POSTGRESUSER:$POSTGRESUSER"
su $USERNAME -c "psql -c \"create user $POSTGRESUSER;\""

echo "3. Creating database POSTGRES_DB:$POSTGRES_DB"
su $USERNAME -c "psql -c \"create database $POSTGRES_DB;\""

echo "4. Change user password POSTGRES_DB:$POSTGRES_DB"
su $USERNAME -c "psql -c \"alter user $POSTGRESUSER with encrypted password '$POSTGRESPASSWORD';\""

echo "5. Grant POSTGRESUSER:$POSTGRESUSER all privileges on POSTGRES_DB:$POSTGRES_DB"
su $USERNAME -c "psql -c \"grant all privileges on database $POSTGRES_DB to $POSTGRESUSER;\""

PGTEST2=$(netstat -tulpn | grep 5432 | grep LISTEN)

if [ -z "$PGTEST2" ]; then
    echo "PGTEST2:$PGTEST2, cannot continue."
    sleeping
fi

echo "Done prepping the server with the database and user."

cat << EOF > /startup.sh
#!/bin/bash
service postgresql start
while true; do
    sleep 999999999
done
EOF

if [ -f /startup.sh ]; then
    chmod +x /startup.sh
fi

#LOGFILE=/var/log/postgresql/postgresql-12-main.log
#tail -50 -f $LOGFILE

sleeping

#while true; do
#    echo "Making sure the server is running."
#    TEST=$(netstat -tunlp | grep 5432 | grep LISTEN)
#    if [ -z "$TEST" ]; then
#        echo "Restarting the server."
#        service postgresql restart
#    else
#        echo "Server is running."
#    fi
#    sleep 10
#done
