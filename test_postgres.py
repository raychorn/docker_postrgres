import os
import socket
import subprocess

import traceback

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


def drop_all_tables(conn):
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT table_schema,table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_schema,table_name")
        rows = cursor.fetchall()
        for row in rows:
            print("dropping table: {}".format(row[1]))
            cursor.execute("drop table " + row[1] + " cascade")
        cursor.close()
    except Exception as e:
        print('Could not drop_all_tables from the database.')
        print(traceback.format_exc())
        exit(1)
    

def test_database(conn):
    try:
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE hello(id int, value varchar(256))")
        cursor.execute("INSERT INTO hello values(1, 'hello'), (2, 'ciao')")
        cursor.close()
    except Exception as e:
        print('Could not test the database.')
        print(traceback.format_exc())
        exit(1)

try:
    conn = psycopg2.connect(
        host=ip,
        port=5432,
        database=POSTGRES_DB,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD
    )
    print("Connected to database: {}".format(conn))

    print('BEGIN: drop_all_tables')
    drop_all_tables(conn)
    print('END!!! drop_all_tables')

    cursor = conn.cursor()
    cursor.execute("""SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'""")

    test_database(conn)
    conn.commit()

    print('BEGIN: Tables')
    for table in cursor.fetchall():
        print(table)    
    print('END!!! Tables')

    print('BEGIN: drop_all_tables')
    drop_all_tables(conn)
    print('END!!! drop_all_tables')

    print('BEGIN: Tables')
    for table in cursor.fetchall():
        print(table)    
    print('END!!! Tables')

    conn.close ()
except Exception as e:
    print('Could not connect to database.')
    print(traceback.format_exc())
    exit(1)
