#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

set -eu

echo "Creating BPMS database schema..."  

mysql --user=root <<EOSQL
    GRANT ALL ON *.* TO 'jboss'@'localhost' IDENTIFIED BY 'jboss';
    GRANT ALL ON *.* TO 'jboss'@'%' IDENTIFIED BY 'jboss';
    DROP DATABASE IF EXISTS bpms;
    CREATE DATABASE IF NOT EXISTS bpms;
EOSQL

mysql --user=jboss --password=jboss bpms < $SCRIPT_DIR/sql/mysql5-jbpm-schema.sql
mysql --user=jboss --password=jboss bpms < $SCRIPT_DIR/sql/quartz_tables_mysql.sql
mysql --user=jboss --password=jboss bpms < $SCRIPT_DIR/sql/mysql5-dashbuilder-schema.sql 
 
