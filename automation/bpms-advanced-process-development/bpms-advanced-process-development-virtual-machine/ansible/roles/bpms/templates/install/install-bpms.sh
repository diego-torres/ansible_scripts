#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

export BPMS_HOME={{bpms_install_dir}}
export BPMS_ROOT={{bpms_root}}
export MYSQL_BPMS_SCHEMA=bpms
export DASHBOARD=true
export KIE_SERVER=true
export BUSINESS_CENTRAL=true
export KIE_SERVER_CONTROLLER=true
export KIE_SERVER_MANAGED=true

{{install_script_dir}}/{{bpms_install_script_dir}}/{{bpms_install_script}}