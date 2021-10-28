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

CID=$(docker ps -q -f name=postgres12)

if [ -z "$CID" ]; then
    echo "Postgres container not found."
    exit 1
fi

echo "ENTRYPOINT:$ENTRYPOINT --> $CID:/entrypoint.sh"
docker cp $ENTRYPOINT $CID:/entrypoint.sh

docker exec -it $CID /bin/bash -c "chmod +x /entrypoint.sh && /entrypoint.sh 0"
