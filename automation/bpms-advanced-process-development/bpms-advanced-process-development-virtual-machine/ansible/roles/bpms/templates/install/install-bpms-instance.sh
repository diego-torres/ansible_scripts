#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# Allow remote clients to access services executing within this EAP runtime
IP_ADDR=0.0.0.0

RESOURCES_DIR=$SCRIPT_DIR/{{bpms_resources_dir}}
EAP_DISTRO={{eap_distro}}
EAP=$RESOURCES_DIR/$EAP_DISTRO
BPMS_DISTRO={{bpms_distro}}
BPMS=$RESOURCES_DIR/$BPMS_DISTRO
BPMS_HOME=${BPMS_HOME:-/home/jboss/lab}
BPMS_ROOT=${BPMS_ROOT:-bpms}
BPMS_ROOT_ORIG={{bpms_root_orig}}
BPMS_DATA_DIR=$BPMS_HOME/$BPMS_ROOT/data
REPO_DIR=bpms-repo
MYSQL_DRIVER={{bpms_mysql_driver}}
MYSQL_DRIVER_PATH={{bpms_mysql_driver_path}}
MYSQL_MODULE_NAME={{bpms_mysql_module_name}}

# Defaults
DASHBOARD=${DASHBOARD:-true}
KIE_SERVER=${KIE_SERVER:-true}
BUSINESS_CENTRAL=${BUSINESS_CENTRAL:-true}

# Kie-server
BPMS_EXT_DISABLED=${BPMS_EXT_DISABLED:-false}
BRMS_EXT_DISABLED=${BRMS_EXT_DISABLED:-false}
BRP_EXT_DISABLED=${BRP_EXT_DISABLED:-true}
JBPMUI_EXT_DISABLED=${JBPMUI_EXT_DISABLED:-false}
KIE_SERVER_BYPASS_AUTH_USER=${KIE_SERVER_BYPASS_AUTH_USER:-false}

# Managed Kie-server
KIE_SERVER_CONTROLLER=${KIE_SERVER_CONTROLLER:-false}
KIE_SERVER_MANAGED=${KIE_SERVER_MANAGED:-false}

# Database
DATABASE=mysql

# MySql schema
MYSQL_BPMS_SCHEMA=${MYSQL_BPMS_SCHEMA:-bpms}
MYSQL_DASHBUILDER_SCHEMA=${MYSQL_DASHBUILDER_SCHEMA:-dashbuilder}
MYSQL_PQUOTE_REPORTING_SCHEMA=${MYSQL_PQUOTE_REPORTING_SCHEMA:-pquote_reporting}

# Quartz
QUARTZ=${QUARTZ:-true}

# Hosts & Ports
if [ "x$BIND_ADDRESS" == "x" ]
then
  BIND_ADDRESS=$IP_ADDR
fi
KIE_SERVER_PORT=${KIE_SERVER_PORT:-8080}
BUSINESS_CENTRAL_PORT=${BUSINESS_CENTRAL_PORT:-8080}

echo "BUSINESS_CENTRAL=$BUSINESS_CENTRAL"
echo "KIE_SERVER=$KIE_SERVER"
echo "DASHBOARD=$DASHBOARD"

# Helper functions for sed
# https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed
#   quoteRe <text>
function quoteRe() { sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\'$'\n''\\n' <<<"$1" | tr -d '\n'; }

#  quoteSubst <text>
function quoteSubst() {
  IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"$1")
  printf %s "${REPLY%$'\n'}"
}

# Helper function for creating users
function createUser() {
  user=$1
  password=$2
  realm=management
  if [ ! -z $3 ]
  then
    roles=$3
    realm=application
  fi

  if [ "$realm" == "management" ]
  then
    $BPMS_HOME/$BPMS_ROOT/bin/add-user.sh -u $user -p $password -s -sc $BPMS_HOME/$BPMS_ROOT/standalone/configuration
  else
    $BPMS_HOME/$BPMS_ROOT/bin/add-user.sh -u $user -p $password -g $roles -a -s -sc $BPMS_HOME/$BPMS_ROOT/standalone/configuration
  fi
}

# Sanity Checks
if [ -f $EAP ];
then
    echo "File $EAP found"
else
    echo "File $EAP not found. Please put it in the resources folder"
    exit 255
fi

if [ -f $BPMS ];
then
    echo "File $BPMS found"
else
    echo "File $BPMS not found. Please put it in the resources folder"
    exit 255
fi

if [ -f $MYSQL_DRIVER_PATH/$MYSQL_DRIVER ];
then
    echo "File $MYSQL_DRIVER_PATH/$MYSQL_DRIVER installed"
else
    echo "File $MYSQL_DRIVER_PATH/$MYSQL_DRIVER not installed. Please install with yum"
    exit 255
fi

if [ -d $BPMS_HOME/$BPMS_ROOT ];
then
  if [ "$FORCE" = "true" ] ;
    then
      echo "Removing existing installation"
      rm -rf $BPMS_HOME/$BPMS_ROOT
    else
      echo "Target directory already exists. Please remove it before installing BPMS again."
      exit 250
  fi
fi

set -e

# Install bpms
echo "Unzipping EAP"
unzip -q $EAP -d $BPMS_HOME

echo "Unzipping BPMS"
unzip -q -o $BPMS -d $BPMS_HOME

echo "Renaming the EAP dir to $BPMS_ROOT"
mv $BPMS_HOME/$BPMS_ROOT_ORIG $BPMS_HOME/$BPMS_ROOT

# Remove unwanted deployments
if [ ! "$DASHBOARD" = "true" ];
then
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war.*
else
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war.*
  touch $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war.dodeploy
fi

if [ ! "$BUSINESS_CENTRAL" = "true" ];
then
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war.*
else
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war.*
  touch $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war.dodeploy
fi

if [ ! "$KIE_SERVER" = "true" ];
then
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war.*
else
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war.*
  touch $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war.dodeploy
fi

# copy standalone-docker.xml
echo "copy standalone.xml"
cp -p $SCRIPT_DIR/standalone.xml $BPMS_HOME/$BPMS_ROOT/standalone/configuration

# Kie server has no quartz library
if [ ! -f  $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war/WEB-INF/lib/quartz-1.8.5.jar ];
then
   echo "Copying quartz library to kie-server deployment"
   cp $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war/WEB-INF/lib/quartz-1.8.5.jar \
   $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war/WEB-INF/lib
fi

# Remove org.kie.example
echo "Remove org.kie.example"
sed -i 's/property name="org.kie.example" value="true"/property name="org.kie.example" value="false"/' $BPMS_HOME/$BPMS_ROOT/standalone/configuration/standalone.xml

# Relax restrictions on user passwords
sed -i "s/password.restriction=REJECT/password.restriction=RELAX/" $BPMS_HOME/$BPMS_ROOT/bin/add-user.properties

# Create application user jboss:bpms
echo "Create application users jboss:bpms, user1:bpms, busadmin:bpms, kieserver:kieserver1!"
createUser "jboss" "bpms" "admin,analyst,user,kie-server,rest-all"
createUser "busadmin" "bpms" "Administrators,analyst,user,kie-server,rest-all"
createUser "user1" "bpms" "kie-server,rest-task,rest-query"
createUser "kieserver" "kieserver1!" "kie-server,rest-all"

# Create management user admin:admin
echo "Create management user admin:admin"
createUser "admin" "admin"

# Userinfo properties
touch $BPMS_HOME/$BPMS_ROOT/standalone/configuration/bpms-userinfo.properties

# Create directories and set permissions
echo "Make directories for maven and git repo"
mkdir -p $BPMS_DATA_DIR/$REPO_DIR

# Quartz properties
echo "copy standalone.xml"
cp -p $SCRIPT_DIR/quartz.properties $BPMS_HOME/$BPMS_ROOT/standalone/configuration

# Persistence
# Configure datasources
echo "Configure $DATABASE datasource"

# configuration : driver
DRIVER=$(cat $SCRIPT_DIR/$DATABASE-driver-config.xml)
sed -i -e ':a' -e '$!{N;ba' -e '}' -e "s/$(quoteRe "<!-- ##DATASOURCE-DRIVERS## -->")/$(quoteSubst "$DRIVER")/" $BPMS_HOME/$BPMS_ROOT/standalone/configuration/standalone.xml

# configuration : BPMS datasource
BPMS_DATASOURCE=$(cat $SCRIPT_DIR/$DATABASE-bpms-datasource-config.xml)

# configuration : Quartz datasource
QUARTZ_DATASOURCE=$(cat $SCRIPT_DIR/$DATABASE-quartz-datasource-config.xml)

# configuration : pquote_reporting datasource
PQUOTE_REPORTING_DATASOURCE=$(cat $SCRIPT_DIR/$DATABASE-pquote-reporting-datasource-config.xml)

if [ "$QUARTZ" = "true" ];
then
  DATASOURCE=$BPMS_DATASOURCE$'\n'$PQUOTE_REPORTING_DATASOURCE$'\n'$QUARTZ_DATASOURCE
else
  DATASOURCE=$BPMS_DATASOURCE$'\n'$PQUOTE_REPORTING_DATASOURCE
fi
sed -i -e ':a' -e '$!{N;ba' -e '}' -e "s/$(quoteRe "<!-- ##DATASOURCES## -->")/$(quoteSubst "$DATASOURCE")/" $BPMS_HOME/$BPMS_ROOT/standalone/configuration/standalone.xml

# set up mysql module
MYSQL_MODULE_DIR=$(echo $MYSQL_MODULE_NAME | sed 's@\.@/@g')
MYSQL_MODULE=$BPMS_HOME/$BPMS_ROOT/modules/${MYSQL_MODULE_DIR}/main
if [ ! -d $MYSQL_MODULE ];
then
  echo "Setup mysql module"
  mkdir -p $MYSQL_MODULE
  cp -rp $SCRIPT_DIR/mysql-module.xml $MYSQL_MODULE/module.xml
  ln -s $MYSQL_DRIVER_PATH/$MYSQL_DRIVER $MYSQL_MODULE/$MYSQL_DRIVER
fi

# Configure business-central persistence.xml
echo "Configure business-central persistence.xml"
sed -i s/java:jboss\\/datasources\\/ExampleDS/java:jboss\\/datasources\\/jbpmDS/ $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml
sed -i s/org.hibernate.dialect.H2Dialect/org.hibernate.dialect.MySQL5Dialect/ $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml

# Configure JEE default datasource
echo "Configure default datasource in standalone.xml"
sed -i s/java:jboss\\/datasources\\/ExampleDS/java:jboss\\/datasources\\/jbpmDS/ $BPMS_HOME/$BPMS_ROOT/standalone/configuration/standalone.xml

# Configure persistence in dashboard app
echo "Configure persistence Dashboard app"
sed -i s/java:jboss\\/datasources\\/ExampleDS/java:jboss\\/datasources\\/dashbuilderDS/ $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war/WEB-INF/jboss-web.xml

# Edit the following dashbuilder file that defines various out-of-the-box BPM related KPIs
sed -i s/local/java:jboss\\/datasources\\/jbpmDS/ $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war/WEB-INF/deployments/jbpmKPIs_v2.kpis

# Set system properties
# Server settings
echo "Set system properties"
echo $'\n' >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address=$BIND_ADDRESS\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address.management=$BIND_ADDRESS\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address.insecure=$BIND_ADDRESS\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.node.name=server-$IP_ADDR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

if [ "x$JBOSS_PORT_OFFSET" != "x" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.socket.binding.port-offset=$JBOSS_PORT_OFFSET\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# mysql
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.host.ip=$IP_ADDR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.host.port=3306\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.bpms.schema=$MYSQL_BPMS_SCHEMA\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.dashbuilder.schema=$MYSQL_DASHBUILDER_SCHEMA\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.pquote_reporting.schema=$MYSQL_PQUOTE_REPORTING_SCHEMA\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

# business-central
if [ "$BUSINESS_CENTRAL" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.ssh.enabled=true\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.daemon.enabled=true\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.daemon.host=$BIND_ADDRESS\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.ssh.host=$BIND_ADDRESS\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.ext.security.management.api.userManagementServices=WildflyCLIUserManagementService\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

  # Getting the following error at startup when $IP_ADDR = 0.0.0.0
  # ERROR [org.uberfire.ext.security.management.wildfly10.cli.Wildfly10ModelUtil] (default task-13) Error reading realm using CLI commands.: java.io.IOException: java.net.ConnectException: WFLYPRT0053: Could not connect to http-remoting://0.0.0.0:9990. The connection failed
  #echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.ext.security.management.wildfly.cli.host=$IP_ADDR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.ext.security.management.wildfly.cli.host=localhost\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.ext.security.management.wildfly.cli.port=9990\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.guvnor.m2repo.dir=$BPMS_DATA_DIR/m2/repository\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.dir=$BPMS_DATA_DIR/$REPO_DIR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.metadata.index.dir=$BPMS_DATA_DIR/$REPO_DIR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# business-central as kie-server controller
if [ "$BUSINESS_CENTRAL" = "true" -a "$KIE_SERVER_CONTROLLER" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.user=jboss\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.pwd=bpms\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
elif [ "$BUSINESS_CENTRAL" = "true" ]
then
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.user=jboss\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.pwd=bpms\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# kie-server
if [ "$KIE_SERVER" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.id=kie-server-$IP_ADDR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.location=http://${IP_ADDR}:${KIE_SERVER_PORT}/kie-server/services/rest/server\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.server.ext.disabled=$BPMS_EXT_DISABLED\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.drools.server.ext.disabled=$BRMS_EXT_DISABLED\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.optaplanner.server.ext.disabled=$BRP_EXT_DISABLED\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ui.server.ext.disabled=$JBPMUI_EXT_DISABLED\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.repo=$BPMS_DATA_DIR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.bypass.auth.user=$KIE_SERVER_BYPASS_AUTH_USER\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.persistence.ds=java:jboss/datasources/jbpmDS\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.persistence.dialect=org.hibernate.dialect.MySQL5Dialect\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.executor.jms.queue=queue/KIE.SERVER.EXECUTOR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# kie-server with bypass auth user
if [ "$KIE_SERVER" = "true" -a "$KIE_SERVER_BYPASS_AUTH_USER" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ht.callback=props\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djbpm.user.group.mapping=file:${BPMS_HOME}/${BPMS_ROOT}/standalone/configuration/application-roles.properties\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ht.userinfo=props\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djbpm.user.info.properties=file:${BPMS_HOME}/${BPMS_ROOT}/standalone/configuration/bpms-userinfo.properties\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
elif [ "$KIE_SERVER" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ht.callback=jaas\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ht.userinfo=props\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djbpm.user.info.properties=file:${BPMS_HOME}/${BPMS_ROOT}/standalone/configuration/bpms-userinfo.properties\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# managed kie-server
KIE_SERVER_CONTROLLER_IP=$IP_ADDR
if [ "$KIE_SERVER" = "true" -a "$KIE_SERVER_MANAGED" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller=http://${KIE_SERVER_CONTROLLER_IP}:${BUSINESS_CENTRAL_PORT}/business-central/rest/controller\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller.user=kieserver\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller.pwd=kieserver1!\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
elif [ "$KIE_SERVER" = "true" ]
then
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller=http://${KIE_SERVER_CONTROLLER_IP}:${BUSINESS_CENTRAL_PORT}/business-central/rest/controller\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller.user=kieserver\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller.pwd=kieserver1!\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

fi

# quartz properties
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.quartz.properties=${BPMS_HOME}/${BPMS_ROOT}/standalone/configuration/quartz.properties\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

# pquote_reporting dashboards
echo "Configure pquote dashboard"
if [ "$DASHBOARD" = "true" ];
then
  cp -f $SCRIPT_DIR/export.workspace $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war/WEB-INF/deployments/export.workspace
  cp -f $SCRIPT_DIR/kpiExport.kpis $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war/WEB-INF/deployments/kpiExport.kpis
  cp -f $SCRIPT_DIR/pquote-datasource.datasource $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war/WEB-INF/deployments/pquote-datasource.datasource
fi

exit 0
