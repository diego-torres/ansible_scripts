#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

set -eu

echo "Creating pquote_reporting database schema..."

mysql --user=root <<EOSQL
    DROP DATABASE IF EXISTS pquote_reporting;
    CREATE DATABASE IF NOT EXISTS pquote_reporting;
EOSQL

mysql --user=jboss --password=jboss pquote_reporting < $SCRIPT_DIR/sql/pquote-reporting.sql
mysql --user=jboss --password=jboss bpms < $SCRIPT_DIR/sql/pquote_dashbuilder.sql
