# Grafana Solar data

Grafana for solar data from your typical roof-top solar panels.

The preprocessing and SQL insertion scripts handle Solar-Log's
[Solar-log Base 100](https://www.solar-log.com/de/produkte-komponenten/solar-logTM-hardware/solar-log-base/)
and insert the data into MySQL Database.

Files are copied from FTP-Server into the RAW directory.


To create the schema, run:
    mysql -h localhost -u root -P < sql/createTables.sql

# Caveat with older Solar-Log Base 100 CSV files
The Solar-Log Base 100 had an issue with the exported CSV datasets:
While all columns are properly separated by ";", the adjacent lines of
two converters attached to the same Solar-Log are not.
So instead of 40 lines, it's only 39 lines...

Use the `preprocess.sh` script to prepare the data.

# Processing 
Afterwards create the SQL INSERT statements using the `sql.sh` script.
This script expects this data to be in sub-directory RAW.
It converts file min200903.csv into min200903.sql

All of these files may be concatenated into one SQL file:
    cat min*.sql > min.sql
    mysql -h localhost -u root -P < min.sql 



    
