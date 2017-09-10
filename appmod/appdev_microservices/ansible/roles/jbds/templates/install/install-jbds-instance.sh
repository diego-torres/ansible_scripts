#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

RESOURCES_DIR=$SCRIPT_DIR/{{jbds_resources_dir}}
CONFIGURATION_DIR=$SCRIPT_DIR/{{jbds_configuration_dir}}
JBDS_DISTRO={{jbds_distro}}
JBDS=$RESOURCES_DIR/$JBDS_DISTRO
JBDS_HOME=${JBDS_HOME:-/home/{{user}}/lab}
JBDS_ROOT=${JBDS_ROOT:-/jbdevstudio}
JBDS_CONFIG=$CONFIGURATION_DIR/{{jbds_install_config}}
JBDS_CONFIG_WORK=/tmp/jbds-install-config-work.xml
JAVA_HOME=/usr/lib/jvm/java

FORCE=false

#
# Check prerequisites
#
function check_prerequisites {

  if [ ! -f $JBDS ] 
  then
    echo "File $JBDS not found. Please put it in the $RESOURCES_DIR folder."
    exit 250
  else 
    echo "File $JBDS found." 
  fi

}

#
# Install JBDS
#
function install_jbds {

  if [ -d $JBDS_HOME/$JBDS_ROOT ]
    then
      if [ $FORCE = "true" ]
        then
          echo "Removing existing JBDS installation"
          rm -rf $JBDS_HOME/$JBDS_ROOT
        else  
          echo "JBDS installation directory already exists. Please remove it before installing JBDS again, or use --force to force a new installation."
          exit 250
      fi
  fi

  echo "Installing JBDS in $JBDS_HOME/${JBDS_ROOT}"
  cp -f ${JBDS_CONFIG} ${JBDS_CONFIG_WORK}
  sed -i -e "s/%PATH%/$(echo $JBDS_HOME/${JBDS_ROOT} | sed -e 's/[\/&]/\\&/g')/g" ${JBDS_CONFIG_WORK}
  sed -i -e "s/%JRE%/$(echo ${JAVA_HOME}/bin/java | sed -e 's/[\/&]/\\&/g')/g" ${JBDS_CONFIG_WORK}

  java -jar ${JBDS} ${JBDS_CONFIG_WORK}

  rm -f ${JBDS_CONFIG_WORK}
}


#
# Configure JBDS
#
function configure_jbds {
  echo "Configuring JBDS"
  
  # set default workspace
  sed -i "s'-Dosgi.instance.area.default=@user.home/workspace'-Dosgi.instance.area.default=${JBDS_HOME}/workspace'" $JBDS_HOME/$JBDS_ROOT/studio/devstudio.ini
}

check_prerequisites
install_jbds
configure_jbds

exit 0





