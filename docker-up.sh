#!/bin/bash

ROOTDIR=$(dirname "$0")
if [ "$ROOTDIR" = "." ]; then
    ROOTDIR=$(pwd)
fi
echo "1. ROOTDIR:$ROOTDIR"

docker-compose up -d

ENTRYPOINT=$ROOTDIR/entrypoint.sh

if [ ! -f "$ENTRYPOINT" ]; then
    echo "Entrypoint script not found."
    exit 1
fi

POSTGRESQLCONF_FILE=postgresql.conf
POSTGRESQLCONF=$ROOTDIR/$POSTGRESQLCONF_FILE

if [ ! -f "$POSTGRESQLCONF" ]; then
    echo "POSTGRESQLCONF:$POSTGRESQLCONF script not found."
    exit 1
fi

PGHBACONF_FILE=pg_hba.conf
PGHBACONF=$ROOTDIR/$PGHBACONF_FILE

if [ ! -f "$PGHBACONF" ]; then
    echo "PGHBACONF:$PGHBACONF script not found."
    exit 1
fi

CID=$(docker ps -q -f name=postgres12)

if [ -z "$CID" ]; then
    echo "Postgres container not found."
    exit 1
fi

echo "ENTRYPOINT:$ENTRYPOINT --> $CID:/entrypoint.sh"
docker cp $ENTRYPOINT $CID:/entrypoint.sh

# BEGIN: DO NOT REMOVE THESE LINES
docker cp $PGHBACONF $CID:/$PGHBACONF_FILE
docker cp $POSTGRESQLCONF $CID:/$POSTGRESQLCONF_FILE
# END!!! DO NOT REMOVE THESE LINES

#docker exec -it $CID /bin/bash -c "ls -la /"

docker exec -it $CID /bin/bash -c "chmod +x /entrypoint.sh && /entrypoint.sh 0"
