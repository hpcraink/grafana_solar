#!/usr/bin/env python3
###############################################################################
# Send the daily solar production (including image) to a list of email adresses
#
# Usage:
#    . mail_daily/bin/activate
#    ./mail_daily.py -i INSTALLATION_ID  -r RECIPIENT_EMAIL_ADDRESSES
#
# Author: Rainer Keller
###############################################################################
# Please make sure, that the requirements.txt contains the imported packages
import os
import time
import datetime
from argparse import ArgumentParser

"""Send the daily solar production as image to a list of email addresses."""

import smtplib
import mimetypes
from email.message import EmailMessage
from email.policy import SMTP
from email.utils import make_msgid

# Modules for retrieving SQL
import mysql.connector
from mysql.connector import Error

# Use MatPlotLib to draw
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import pandas as pd

from dateutil.rrule import rrule, SECONDLY

today=time.localtime()

# All settings not to be visible in GIT belong here -- including i8n text for mail & mail-adresses!
from mail_daily_settings import MYSQL_CONFIG, SMTP_SERVER, FILENAME, DIR, LANG
from mail_daily_settings_de import mail_from_address, mail_subject, mail_today, mail_html_body

def sql_connection():
    connection = None
    try:
        connection = mysql.connector.connect(**MYSQL_CONFIG)
    except Error as e:
        print(f"Error '{e}' occurred in accessing MySQL")
    return connection


def send_email(recipients, peak_kW, kWh_today, max_kW_today, kWh_max_ever, kW_max_ever, best_day, error_text, img_path):
    msg_cid = make_msgid()
    msg = EmailMessage()
    msg['Subject'] = f'{mail_subject} {mail_today}'
    msg['From'] = mail_from_address
    msg['To'] = ', '.join(recipients)
    msg.preamble = 'Please use a MIME-aware mail reader.\n'
    html_body = mail_html_body.format(
           date_year=today.tm_year,
           date_month=today.tm_mon,
           date_day=today.tm_mday,
           date_hour=today.tm_hour,
           date_minute=today.tm_min,
           date_seconds=today.tm_sec,
           kWh_today=kWh_today,
           percentMax_kWh=float(kWh_today)/kWh_max_ever*100.0,
           kWh_max_ever=kWh_max_ever,
           best_day=best_day,
           max_kW_today=max_kW_today,
           percentPeak_kW=float(max_kW_today)/peak_kW*100.0,
           peak_kW=peak_kW,
           percentMaxEver_kW=float(max_kW_today)/kW_max_ever*100.0,
           kW_max_ever=kW_max_ever,
           error=error_text,
           msg_cid=msg_cid[1:-1])
    msg.set_content=html_body
    msg.add_alternative(html_body, subtype='html')

    ctype, encoding = mimetypes.guess_type(img_path)
    if ctype is None or encoding is not None:
        # No guess could be made, or the file is encoded (compressed), so
        # use a generic bag-of-bits type.
        ctype = 'application/octet-stream'

    maintype, subtype = ctype.split('/', 1)

    with open(img_path, 'rb') as img:
        msg.get_payload()[0].add_related(img.read(),
                                         maintype=maintype,
                                         subtype=subtype,
                                         cid=msg_cid)

    with smtplib.SMTP(SMTP_SERVER) as s:
        s.send_message(msg)

def error_analyze(data):
    error_text = ""
    df = pd.DataFrame(data, columns=['DateAndTime', 'inverterID', 'temp', 'status', 'error'])

    result = df[df['error'] != 0]
    if not result.empty:
        error_text += "Error: Error value:" + result.iat[0, 4] + " at time " + result.iat[0, 0] + ".<BR>"

    result = df[df['temp'] > 50]
    if not result.empty:
        error_text += "Warning: Temperature was >50°C :" + str(result.iat[0, 2]) + " at time " + result.iat[0, 0] + ".<BR>"

    # See docs/status_codes.txt -- warn upon any OTHER (unknown) code:
    result = df[~df['status'].isin([0, 1, 2, 3, 4, 5, 16])]
    if not result.empty:
        error_text += "Warning: Unknown Status (unequal 0, 1, 2, 3, 4, 5, 16):" + str(result.iat[0, 2]) + " at time " + result.iat[0, 0] + ".<BR>"

    if "".__eq__(error_text):
        error_text = "No errors detected during timeframe.<BR>"
    return error_text

def sql_get_data(installation):
    connection = sql_connection()
    cursor = connection.cursor()

    ############## Gather current and historic data ##############
    query = "SELECT inverterID FROM installation WHERE siteID=%s"
    cursor.execute(query, [installation[1]])
    data = cursor.fetchall()
    inverter = []
    for i in data:
        inverter.append(i[0])

    format_strings = ','.join(['%s'] * len(inverter))
    query = "SELECT SUM(installedpower) FROM inverter WHERE id IN (" + format_strings + ")"
    cursor.execute(query, inverter)
    data = cursor.fetchone()
    kW_peak = float(data[0])/1000.0

    query = "SELECT MAX(WattHours)/1000.0 AS kWh_today FROM viewTotalEnergy WHERE dateAndTime BETWEEN %s AND %s"
    cursor.execute(query,
                   (datetime.date(today.tm_year, today.tm_mon, today.tm_mday),
                    datetime.datetime(today.tm_year, today.tm_mon, today.tm_mday, 23, 59, 59)))
    data = cursor.fetchone()
    kWh_today = data[0]

    query = "SELECT MAX(Watt)/1000.0 AS max_kW_today FROM viewCurrentPower WHERE dateAndTime BETWEEN %s AND %s"
    cursor.execute(query,
                   (datetime.date(today.tm_year, today.tm_mon, today.tm_mday),
                    datetime.datetime(today.tm_year, today.tm_mon, today.tm_mday, 23, 59, 59)))
    data = cursor.fetchone()
    max_kW_today = data[0]

    query = "SELECT MAX(WattHours) AS Wh_max_ever FROM viewTotalEnergy"
    cursor.execute(query)
    data = cursor.fetchone()
    Wh_max_ever = data[0]
    kWh_max_ever = float(Wh_max_ever)/1000.0

    query = "SELECT MAX(Watt) AS W_max_ever FROM viewCurrentPower"
    cursor.execute(query)
    data = cursor.fetchone()
    W_max_ever = data[0]
    kW_max_ever = float(W_max_ever)/1000.0

    query = "SELECT YEAR(MAX(dateAndTime)) AS best_day_year, MONTH(MAX(dateAndTime)) AS best_day_month, DAY(MAX(dateAndTime)) AS best_day FROM viewTotalEnergy WHERE WattHours=%(Wh_max_ever)s"
    cursor.execute(query, { 'Wh_max_ever': Wh_max_ever })
    data = cursor.fetchone()
    best_day_year = data[0]
    best_day_month = data[1]
    best_day_day = data[2]

    query = "SELECT dateAndTime, Watt FROM viewCurrentPower WHERE dateAndTime BETWEEN %s AND %s GROUP BY dateAndTime"
    cursor.execute(query,
                   (datetime.date(best_day_year, best_day_month, best_day_day),
                    datetime.datetime(best_day_year, best_day_month, best_day_day, 23, 59, 59)))
    data = cursor.fetchall()
    df_best_day = pd.DataFrame(data)
    num_best_rows = df_best_day.count(0)[0]

    ############## Generate Plot ##############
    # SELECT dateAndTime, status, error, totalEnergy, inverterID FROM sample WHERE dateAndTime BETWEEN CAST('2023-08-09' AS datetime) AND CAST('2023-08-09 23:59:59' AS datetime) ;
    query = "SELECT dateAndTime, Watt FROM viewCurrentPower WHERE dateAndTime BETWEEN %s AND %s GROUP BY dateAndTime"
    cursor.execute(query,
                   (datetime.date(today.tm_year, today.tm_mon, today.tm_mday),
                    datetime.datetime(today.tm_year, today.tm_mon, today.tm_mday, 23, 59, 59)))
    data = cursor.fetchall()
    num_data_rows = cursor.rowcount
    # In case we have fewer data points, full up with zero values!
    if (num_data_rows < num_best_rows):
        startdate = data[num_data_rows-1][0]
        before = data[num_data_rows-2][0]
        diff = startdate - before
        startdate = startdate + diff
        for i in list(rrule(freq=SECONDLY, interval=diff.seconds, dtstart=startdate, count=(num_best_rows - num_data_rows))):
            data.append((i, 0))

    df_today = pd.DataFrame(data)

    plt.plot(df_today[0], df_today[1], label='W | today', linewidth=2)
    plt.plot(df_today[0], df_best_day[1], label='W | best day ever')
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
    plt.gca().xaxis.set_major_locator(mdates.HourLocator())
    plt.xticks(rotation=45)
    plt.title("Solar Energy")
    img_path = os.path.join(DIR, FILENAME)
    plt.savefig(img_path, format="png", dpi=200)

    if not os.path.isfile(img_path):
        print(f'File {path} is not available or has not been created by MatPlotLib')
        exit(-1)

    # Get any errors
    format_strings = ','.join(['%s'] * len(inverter))
    query = "SELECT dateAndTime, inverterID, temp, status, error FROM sample WHERE (dateAndTime BETWEEN %s AND %s) AND inverterID in (" + format_strings + ")"
    cursor.execute(query,
                   (datetime.date(today.tm_year, today.tm_mon, today.tm_mday),
                    datetime.datetime(today.tm_year, today.tm_mon, today.tm_mday, 23, 59, 59),
                    *inverter))
    data = cursor.fetchall()
    error_text = error_analyze(data)

    cursor.close()
    connection.close()

    return kW_peak, kWh_today, max_kW_today, kWh_max_ever, kW_max_ever, datetime.date(best_day_year, best_day_month, best_day_day), img_path, error_text



def main():
    parser = ArgumentParser(description="""\
                            Send the daily solar production to the recipients specified via the -r argument.
                            """)
    parser.add_argument('-i', '--installation',
                        required=True,
                        action='append', metavar='INSTALLATION',
                        default=[1], dest='installation',
                        help="""The number of the installation to report""")
    parser.add_argument('-r', '--recipient',
                        required=False,
                        action='append', metavar='RECIPIENT',
                        default=['rainer.keller@hs-esslingen.de'], dest='recipients',
                        help="""A To: header value (at least one required)""")
    args = parser.parse_args()

    kW_peak, kWh_today, max_kW_today, kWh_max_ever, kW_max_ever, best_day, img_path, error_text = sql_get_data(args.installation)

    send_email(args.recipients, kW_peak, kWh_today, max_kW_today, kWh_max_ever, kW_max_ever, best_day, error_text, img_path)

if __name__ == '__main__':
    main()
