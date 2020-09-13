#!/bin/sh

RAW_DIR=RAW
OUTPUT_DIR=.

# This should read from MySQL DB as in SELECT MAX(dateAndTime) FROM samplePerInverter;
LAST_IMPORT_FILE=".lastimport"

LAST_IMPORT=0
if test -f $LAST_IMPORT_FILE ; then
    LAST_IMPORT=`cat $LAST_IMPORT_FILE`
fi

for i in $RAW_DIR/min*.csv; do
    FILE=`basename $i`
    YEAR=20`echo $FILE | cut -c4-5`;
    MONTH=`echo $FILE | cut -c6-7`;
    DAY=`echo $FILE | cut -c8-9`;
    FILE_DATE="$YEAR$MONTH$DAY"
    if test $FILE_DATE -lt $LAST_IMPORT ; then
        echo FILE $i date $FILE_DATE is lower than last import:$LAST_IMPORT
        continue
    fi

    echo $i $FILE $OUTPUT_DIR/$i
    TMPFILE=`basename $i .csv`.tmp
    iconv -f ISO-8859-2 -t UTF-8 $i > $TMPFILE
    awk 'BEGIN { FS = OFS = ";" } {  sub( /[[:digit:]]/, "0;", $21) ; print }' $TMPFILE > $OUTPUT_DIR/$FILE
done
rm -f min*.tmp
