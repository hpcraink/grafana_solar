#!/usr/bin/env python3
import time
today=time.localtime()

MYSQL_CONFIG = {
    'host': 'SET_HOSTNAME',
    'user': 'SET_USERNAME',
    'passwd': 'SET_PASSWD',
    'database': 'SET_DBNAME'
}

SMTP_SERVER='localhost'
FILENAME=f'solar_production-{today.tm_year}.{today.tm_mon:02}.{today.tm_mday:02}.png'
DIR='.'

LANG='de'
