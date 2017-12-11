#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

export BPMS_HOME={{bpms_install_dir}}
export BPMS_ROOT=bc
export MYSQL_BPMS_SCHEMA=bpms
export DASHBOARD=true
export KIE_SERVER=false
export BUSINESS_CENTRAL=true
export BIND_ADRESS=127.0.0.1
export QUARTZ=false
export KIE_SERVER_CONTROLLER=true

{{install_script_dir}}/{{bpms_install_script_dir}}/{{bpms_install_script}}

export JBOSS_PORT_OFFSET=150
export KIE_SERVER_PORT=8230
export BPMS_HOME={{bpms_install_dir}}
export BPMS_ROOT=kieserver
export MYSQL_BPMS_SCHEMA=bpms
export DASHBOARD=false
export KIE_SERVER=true
export BUSINESS_CENTRAL=false
export BIND_ADRESS=127.0.0.1
export QUARTZ=true
export BRP_EXT_DISABLED=false
export KIE_SERVER_MANAGED=true

{{install_script_dir}}/{{bpms_install_script_dir}}/{{bpms_install_script}}
