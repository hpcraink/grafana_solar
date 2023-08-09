#!/bin/bash

###########################################################################
# Convert the SolarLog Base 100  CSV files into SQL files for the schema.
#
# Author: Rainer Keller
###########################################################################

. ~/.mysql_values.sh

LAST_IMPORT_FILE=".lastimport"

INPUT_DIR=preprocessed
OUTPUT_DIR=processed

LAST_IMPORT=0
if test \! -f $LAST_IMPORT_FILE ; then
    write_last_import_file $LAST_IMPORT_FILE
fi
LAST_IMPORT=`cat $LAST_IMPORT_FILE`


function create_import_file {
    if [ $# -ne 3 ] ; then
        echo Need 3 parameters: SITE_NAME CSV-File SQL-File
    fi
    SITE_NAME=$1
    CSV_FILE=$2
    SQL_FILE=$3

    rm -f $SQL_FILE
    echo "SET @siteID = (SELECT id FROM site WHERE name LIKE '%${SITE_NAME}%');" >> $SQL_FILE
    # XXX This would need to be generalized for installations with different number of inverters
    echo "SET @inverterID0 = (SELECT inverterID FROM installation WHERE siteID=@siteID LIMIT 1);" >> $SQL_FILE
    echo "SET @inverterID1 = (SELECT inverterID FROM installation WHERE siteID=@siteID LIMIT 1,1);" >> $SQL_FILE

    echo "INSERT IGNORE INTO sample(dateAndtime, inverterID, totalEnergy, pac, uac, iac, udc0, idc0, pdc0, udc1, idc1, pdc1, udc2, idc2, pdc2, udc3, idc3, pdc3, temp, status, error) VALUES" >> $SQL_FILE

    NUM_LINES=$(( `wc -l $CSV_FILE | cut -f1 -d' '` - 2 ))
    I=1  # Have to start from 1 so that we may use -eq in hte test below.

    while read LINE ; do
        if [ "${LINE:0:1}" = '#' -o "${LINE:0:1}" = "D" ] ; then
            continue
        fi
        # echo $LINE:$LINE
        V=(`echo $LINE | tr ';' ' '`)
        DATE=${V[0]}
        YEAR=20`echo $DATE | cut -f3 -d'.'`
        MONTH=`echo $DATE | cut -f2 -d'.'`
        DAY=`echo $DATE | cut -f1 -d'.'`
        TIME=${V[1]}
        SQL_DATE="$YEAR-$MONTH-${DAY} ${TIME}"
     
        # XXX Again this would have to be generalized if the number of inverters, or the number of MPP-Trackers  differs
        # First the values for Inverter0, ended by Comma
        echo "    ('"$SQL_DATE"', @inverterID0, ${V[2]}, ${V[3]}, ${V[4]}, ${V[5]}, ${V[6]}, ${V[7]}, ${V[8]}, ${V[9]}, ${V[10]}, ${V[11]}, ${V[12]}, ${V[13]}, ${V[14]}, ${V[15]}, ${V[16]}, ${V[17]}, ${V[18]}, ${V[19]}, ${V[20]})," >> $SQL_FILE

        # Next the values for Inverter1, not ended by Comma (might be the last line --> ;)
        echo -n "    ('"$SQL_DATE"', @inverterID1, ${V[21]}, ${V[22]}, ${V[23]}, ${V[24]}, ${V[25]}, ${V[26]}, ${V[27]}, ${V[28]}, ${V[29]}, ${V[30]}, ${V[31]}, ${V[32]}, ${V[33]}, ${V[34]}, ${V[35]}, ${V[36]}, ${V[37]}, ${V[38]}, ${V[39]})" >> $SQL_FILE

        if test $I -eq $NUM_LINES ; then
            echo ";" >> $SQL_FILE
        else
            echo "," >> $SQL_FILE
            I=$(( $I + 1 ))
        fi 

    done < $CSV_FILE
}

for i in `ls -1 $INPUT_DIR/min*.csv | sort -n`; do
    YEAR=`filename $i | cut -c4-5`;
    MONTH=`filename $i | cut -c6-7`;
    DAY=`filename $i | cut -c8-9`;
    FILE_DATE="$YEAR$MONTH$DAY"
    # echo FILE_DATE:$FILE_DATE LAST_IMPORT:$LAST_IMPORT result:`test $FILE_DATE -lt $LAST_IMPORT`
    if test $FILE_DATE -lt $LAST_IMPORT ; then
        # echo FILE $i date $FILE_DATE is lower than last import:$LAST_IMPORT
        continue
    fi
    SQL_FILE=$OUTPUT_DIR/`basename $i .csv`.sql
    echo Working on File $i, creating and importing $SQL_FILE
    # Create the SQL statement to import values
    create_import_file Stittholz $i $SQL_FILE
    
    mysql_import_file $SQL_FILE
done

# Finally write the .lastimport file again:
write_last_import_file $LAST_IMPORT_FILE
