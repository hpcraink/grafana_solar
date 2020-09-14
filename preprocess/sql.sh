#!/bin/sh

###########################################################################
# Convert the SolarLog Base 100  CSV files into SQL files for the schema.
#
# Author: Rainer Keller
###########################################################################

LAST_IMPORT_FILE=".lastimport"


LAST_IMPORT=0
if test -f $LAST_IMPORT_FILE ; then
    LAST_IMPORT=`cat $LAST_IMPORT_FILE`
fi


function create_import_file {
    if [ $# -ne 3 ] ; then
        echo Need 3 parameters: SITE_ID CSV-File SQL-File
    fi
    SITE_ID=$1
    CSV_FILE=$2
    SQL_FILE=$3

    echo "USE solardb;" > $SQL_FILE
    echo "SET @inverterID0 = (SELECT inverterID FROM installation WHERE siteID=$SITE_ID LIMIT 1);" >> $SQL_FILE
    echo "SET @inverterID1 = (SELECT inverterID FROM installation WHERE siteID=$SITE_ID LIMIT 1,1);" >> $SQL_FILE
    echo "-- just to keep it SET @lastID = (SELECT id FROM sample WHERE siteID=$SITE_ID AND time=$SQL_DATE)" >> $SQL_FILE


    echo "INSERT INTO samplePerInverter(dateAndtime, inverterID, totalEnergy, pac, uac, iac, udc0, idc0, pdc0, udc1, idc1, pdc1, udc2, idc2, pdc2, udc3, idc3, pdc3, temp, status, error) VALUES" >> $SQL_FILE

    NUM_LINES=$(( `wc -l $CSV_FILE | cut -c1-9` - 2 ))
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

for i in `ls -1 min*.csv | sort -n`; do
    YEAR=20`echo $i | cut -c4-5`;
    MONTH=`echo $i | cut -c6-7`;
    DAY=`echo $i | cut -c8-9`;
    FILE_DATE="$YEAR$MONTH$DAY"
    if test $FILE_DATE -lt $LAST_IMPORT ; then
        echo FILE $i date $FILE_DATE is lower than last import:$LAST_IMPORT
        continue
    fi
    echo Working on File $i
    # Create the SQL statement to import values
    create_import_file 1 $i `basename $i .csv`.sql

    echo $FILE_DATE > $LAST_IMPORT_FILE
done

