#!/usr/bin/env python3
import os
import time
import datetime
from argparse import ArgumentParser
#### from decimal import * ### XXX needed, or may be deleted?

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


def send_email(recipients, peak_kW, kWh_today, max_kW_today, kWh_max_ever, kW_max_ever, best_day, img_path):
    msg_cid = make_msgid()
    msg = EmailMessage()
    msg['Subject'] = f'{mail_subject} {mail_today}'
    msg['From'] = mail_from_address
    msg['To'] = ', '.join(recipients)
    msg.preamble = 'Please use a MIME-aware mail reader.\n'
    html_body = mail_html_body.format(
           tag=today,
           kWh_today=kWh_today,
           percentMax_kWh=float(kWh_today)/kWh_max_ever*100.0,
           kWh_max_ever=kWh_max_ever,
           best_day=best_day,
           max_kW_today=max_kW_today,
           percentPeak_kW=float(max_kW_today)/peak_kW*100.0,
           peak_kW=peak_kW,
           percentMaxEver_kW=float(max_kW_today)/kW_max_ever*100.0,
           kW_max_ever=kW_max_ever,
           error="Error detection not yet implemented!",
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

def sql_get_data(installation):
    connection = sql_connection()
    cursor = connection.cursor()

    ############## Gather current and historic data ##############
    '''#[
    query = ("SELECT inverterID FROM installation WHERE siteID=%d")
    cursor.execute(query, installation)
    data = cursor.fetchall()
    inverter = [].append(data)

    query = ("SELECT SUM(installedpower) FROM inverter WHERE id IN (%s)")
    cursor.execute(query, inverter)
    data = cursor.fetchone()
    kW_peak = data[0]
    #]'''
    kW_peak = 82.15

    query = ("SELECT MAX(WattHours)/1000.0 AS kWh_today FROM viewTotalEnergy WHERE dateAndTime BETWEEN %s AND %s")
    cursor.execute(query,
                   (datetime.date(today.tm_year, today.tm_mon, today.tm_mday),
                    datetime.datetime(today.tm_year, today.tm_mon, today.tm_mday, 23, 59, 59)))
    data = cursor.fetchone()
    kWh_today = data[0]

    query = ("SELECT MAX(Watt)/1000.0 AS max_kW_today FROM viewCurrentPower WHERE dateAndTime BETWEEN %s AND %s")
    cursor.execute(query,
                   (datetime.date(today.tm_year, today.tm_mon, today.tm_mday),
                    datetime.datetime(today.tm_year, today.tm_mon, today.tm_mday, 23, 59, 59)))
    data = cursor.fetchone()
    max_kW_today = data[0]

    query = ("SELECT MAX(WattHours) AS Wh_max_ever FROM viewTotalEnergy")
    cursor.execute(query)
    data = cursor.fetchone()
    Wh_max_ever = data[0]
    kWh_max_ever = float(Wh_max_ever)/1000.0

    query = ("SELECT MAX(Watt) AS W_max_ever FROM viewCurrentPower")
    cursor.execute(query)
    data = cursor.fetchone()
    W_max_ever = data[0]
    kW_max_ever = float(W_max_ever)/1000.0

    query = ("SELECT YEAR(MAX(dateAndTime)) AS best_day_year, MONTH(MAX(dateAndTime)) AS best_day_month, DAY(MAX(dateAndTime)) AS best_day FROM viewTotalEnergy WHERE WattHours=%(Wh_max_ever)s")
    cursor.execute(query, { 'Wh_max_ever': Wh_max_ever })
    data = cursor.fetchone()
    best_day_year = data[0]
    best_day_month = data[1]
    best_day_day = data[2]

    query = ("SELECT dateAndTime, Watt FROM viewCurrentPower WHERE dateAndTime BETWEEN %s AND %s GROUP BY dateAndTime")
    cursor.execute(query,
                   (datetime.date(best_day_year, best_day_month, best_day_day),
                    datetime.datetime(best_day_year, best_day_month, best_day_day, 23, 59, 59)))
    data = cursor.fetchall()
    df_best_day = pd.DataFrame(data)

    ############## Generate Plot ##############
    # SELECT dateAndTime, status, error, totalEnergy, inverterID FROM sample WHERE dateAndTime BETWEEN CAST('2023-08-09' AS datetime) AND CAST('2023-08-09 23:59:59' AS datetime) ;
    query = ("SELECT dateAndTime, Watt FROM viewCurrentPower WHERE dateAndTime BETWEEN %s AND %s GROUP BY dateAndTime")
    cursor.execute(query,
                   (datetime.date(today.tm_year, today.tm_mon, today.tm_mday),
                    datetime.datetime(today.tm_year, today.tm_mon, today.tm_mday, 23, 59, 59)))
    data = cursor.fetchall()
    df_today = pd.DataFrame(data)

    #### XXX Have to make sure, that the number of values to be printed are the same!

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

    cursor.close()
    connection.close()

    return kW_peak, kWh_today, max_kW_today, kWh_max_ever, kW_max_ever, datetime.date(best_day_year, best_day_month, best_day_day), img_path



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

    kW_peak, kWh_today, max_kW_today, kWh_max_ever, kW_max_ever, best_day, img_path = sql_get_data(args.installation)


    #### XXX Get the maximum peak value from DB
    send_email(args.recipients, kW_peak, kWh_today, max_kW_today, kWh_max_ever, kW_max_ever, best_day, img_path)

if __name__ == '__main__':
    main()
