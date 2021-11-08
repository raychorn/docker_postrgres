import os
import socket
import subprocess

import psycopg2

POSTGRES_USER = 'securexdev'
POSTGRES_PASSWORD = 'secureme2020'
POSTGRES_DB = 'securex_assets'

CMD = 'ip r | grep /24'

lines = subprocess.check_output(CMD, shell=True).decode('utf-8').split('\n')

ip = None
for item in lines:
    ips = [t for t in item.split() if (len(t.split('.')) == 4) and (all(t.split('.')[i].isdigit() for i in range(4)))]
    if (len(ips) > 0):
        ip = ips[0]
        break

_ip = socket.gethostbyname(socket.gethostname())

assert (ip is not None) and (ip == _ip), 'Could not find IP address or the ip address found does not match the hosts file.'

# psql -h 127.0.0.1 -p 5432 -d securex_assets -U securexdev -W

conn = psycopg2.connect(
    host=ip,
    database=POSTGRES_DB,
    user=POSTGRES_USER,
    password=POSTGRES_PASSWORD)

print("Connected to database: {}".format(conn))
