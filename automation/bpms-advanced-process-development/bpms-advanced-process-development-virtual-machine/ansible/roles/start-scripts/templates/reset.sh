#!/bin/bash

LAB_HOME_DIR={{lab_home_dir}}
BPMS_HOME=$LAB_HOME_DIR/{{bpms_root}}
SQL_BASE={{install_script_dir}}/{{mysqlddl_install_script_dir}}/sql
MYSQL_FLAGS="-u root"
JBDS_WORKSPACE=$LAB_HOME_DIR/workspace

echo "Resetting BPMS"
rm -rf $BPMS_HOME/data
rm -rf $BPMS_HOME/standalone/data
rm -rf $BPMS_HOME/standalone/tmp
rm -rf $BPMS_HOME/standalone/log/*

echo "Resetting MySQL"
mysql $MYSQL_FLAGS <<EOSQL
    DROP DATABASE bpms;
    CREATE DATABASE IF NOT EXISTS bpms;
    DROP DATABASE dashbuilder;
    CREATE DATABASE IF NOT EXISTS dashbuilder;
EOSQL

mysql $MYSQL_FLAGS bpms < $SQL_BASE/mysql5-jbpm-schema.sql
mysql $MYSQL_FLAGS bpms < $SQL_BASE/quartz_tables_mysql.sql
mysql $MYSQL_FLAGS dashbuilder < $SQL_BASE/mysql5-dashbuilder-schema.sql

echo "Remove JBDS Workspace"
if [ -d $JBDS_WORKSPACE ];
then
  rm -rf $JBDS_WORKSPACE
fi
