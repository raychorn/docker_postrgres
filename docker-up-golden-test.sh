#!/bin/bash

ROOTDIR=$(dirname "$0")
if [ "$ROOTDIR" = "." ]; then
    ROOTDIR=$(pwd)
fi
echo "1. ROOTDIR:$ROOTDIR"

docker-compose -f docker-compose-golden-test.yml up -d

CID=$(docker ps -q -f name=postgres12)

if [ -z "$CID" ]; then
    echo "Postgres container not found."
    exit 1
fi

echo "2. CID:$CID"
echo "Done."
