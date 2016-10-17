!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

RESOURCES_DIR=$SCRIPT_DIR/{{soapui_resources_dir}}
SOAPUI_BASE_DIR_ORIG={{soapui_root_orig}}
SOAPUI_BASE_DIR={{soapui_root}}
SOAPUI_DISTRO={{soapui_distro}}
SOAPUI=$RESOURCES_DIR/$SOAPUI_DISTRO
SOAPUI_INSTALL_DIR={{soapui_install_dir}}

FORCE=false

#
# Check prerequisites
#
function check_prerequisites {

  if [ ! -f $SOAPUI ] 
  then
    echo "File $SOAPUI not found. Please put it in the $RESOURCES_DIR folder."
    exit 250
  else 
    echo "File $SOAPUI found." 
  fi

}

#
# Install SoapUI
#
function install_soapui {

  if [ -d $SOAPUI_INSTALL_DIR/$SOAPUI_BASE_DIR ]
    then
      if [ $FORCE = "true" ]
        then
          echo "Removing existing SoapUI installation"
          rm -rf $SOAPUI_INSTALL_DIR/$SOAPUI_BASE_DIR
        else  
          echo "SoapUI installation directory already exists. Please remove it before installing SoapUI again, or use --force to force a new installation."
          exit 250
      fi
  fi

  echo "Installing SoapUI in $SOAPUI_INSTALL_DIR/$SOAPUI_BASE_DIR"
  tar -zxf $SOAPUI -C $SOAPUI_INSTALL_DIR
  mv $SOAPUI_INSTALL_DIR/$SOAPUI_BASE_DIR_ORIG $SOAPUI_INSTALL_DIR/$SOAPUI_BASE_DIR 
}

check_prerequisites
install_soapui

exit 0