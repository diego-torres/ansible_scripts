#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

HOME_DIR=/home/{{user}}
LAB_DIR={{lab_home_dir}}
RESOURCES_DIR=$SCRIPT_DIR/{{mvn_resources_dir}}
CONFIGURATION_DIR=$SCRIPT_DIR/{{mvn_configuration_dir}}
MVN_DISTRO={{mvn_distro}}
MVN=$RESOURCES_DIR/$MVN_DISTRO
MVN_ROOT_DIR={{mvn_root}}
MVN_INSTALL_DIR={{mvn_install_dir}}
MVN_SETTINGS=$CONFIGURATION_DIR/mvn-settings.xml


#
# Check prerequisites
#
function check_prerequisites {

  if [ ! -f $MVN ] 
  then
    echo "File $MVN not found. Please put it in the $RESOURCES_DIR folder."
    exit 250
  else 
    echo "File $MVN found." 
  fi

}

#
# Install Maven
#
function install_mvn {

  echo "Installing Maven in ${MVN_INSTALL_DIR}"
  unzip $MVN -d $MVN_INSTALL_DIR
  if [ ! -d $HOME_DIR/.m2 ]
    then 
      mkdir $HOME_DIR/.m2  
  fi
  cp -f $MVN_SETTINGS $HOME_DIR/.m2/settings.xml
  
  RET=`cat $HOME_DIR/.bashrc | grep "M2_HOME=" | grep -v "#"`
  if [[ "$RET" == "" ]]
    then
      echo $'\n' >> $HOME_DIR/.bashrc
      echo "export M2_HOME=$MVN_INSTALL_DIR/$MVN_ROOT_DIR" >> $HOME_DIR/.bashrc
      echo "export PATH=\$M2_HOME/bin:\$PATH" >> $HOME_DIR/.bashrc
  fi

}

check_prerequisites
install_mvn

exit 0