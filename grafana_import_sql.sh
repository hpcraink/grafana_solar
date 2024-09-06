#!/bin/bash
cd $HOME/grafana_solar

LAST_IMPORT_FILE=".lastimport"

if test \! -f $LAST_IMORT_FILE ; then
    echo "File $LAST_IMPORT_FILE expected"
    exit
fi

if test \! -x $HOME/.mysql_values.sh ; then
    echo "File $HOME/.mysql_values.sh does either not exist or is not executable"
    exit
fi

if test \! -x preprocess/preprocess.sh ; then
    echo "File preprocess/preprocess.sh does either not exist or is not executable"
    exit
fi

if test \! -x preprocess/sql.sh ; then
    echo "File preprocess/sql.sh does either not exist or is not executable"
    exit
fi

# If the last imported file's date (e.g. min200913.csv) is
# newer than the file-date of .last_import, work 
LAST_MIN_FILE="min`cat $LAST_IMPORT_FILE`.csv"

# Now preprocess and import them all
# if test data/"$LAST_MIN_FILE" -nt "$LAST_IMPORT_FILE" ; then
    # In case of proper, correctly ";" separated CSV Files, this script just copies
    . preprocess/preprocess.sh
    . preprocess/sql.sh
# fi
