#!/bin/bash
# This script preprocesses Solar-Logs bungled CSV file, inserting a missing ";"
# into column 20/21...

. ~/.mysql_values.sh

RAW_DIR=data
OUTPUT_DIR=preprocessed

# Get the last imported date from MySQL using the temporary file .lastimport
LAST_IMPORT_FILE=".lastimport"

write_last_import_file $LAST_IMPORT_FILE

for i in $RAW_DIR/min*.csv; do
    FILE=`basename $i`
    YEAR=`echo $FILE | cut -c4-5`;
    MONTH=`echo $FILE | cut -c6-7`;
    DAY=`echo $FILE | cut -c8-9`;
    FILE_DATE="$YEAR$MONTH$DAY"
    # echo FILE_DATE:$FILE_DATE LAST_IMPORT:$LAST_IMPORT result:`test $FILE_DATE -lt $LAST_IMPORT`
    if test $FILE_DATE -lt $LAST_IMPORT ; then
        # echo FILE $i date $FILE_DATE is lower than last import:$LAST_IMPORT
        continue
    fi

    # Starting with 9.12.2020 the firmware corrects the log's format.
    if test $FILE_DATE -ge 201209 ; then
        echo Copy and convert $i into $OUTPUT_DIR/$FILE
        iconv -f ISO-8859-2 -t UTF-8 $i > $OUTPUT_DIR/$FILE
    else
        echo Preprocessing $i into $OUTPUT_DIR/$FILE
        TMPFILE=`basename $i .csv`.tmp
        iconv -f ISO-8859-2 -t UTF-8 $i > $TMPFILE
        awk 'BEGIN { FS = OFS = ";" } {  sub( /[[:digit:]]/, "0;", $21) ; print }' $TMPFILE > $OUTPUT_DIR/$FILE
    fi
done
rm -f min*.tmp
