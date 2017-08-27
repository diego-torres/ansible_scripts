#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

export JBDS_HOME={{jbds_install_dir}}
export JBDS_ROOT={{jbds_root}}

{{install_script_dir}}/{{jbds_install_script_dir}}/{{jbds_install_script}}