#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap /var/lib/ldap/DB_CONFIG

# set config password
export LDAP_CONFIG_PASSWORD_ENCRYPTED=$(slappasswd -s $LDAP_CONFIG_PASSWORD)
envsubst < ${SCRIPT_DIR}/ldif/chrootpw.ldif.template > ${SCRIPT_DIR}/ldif/chrootpw.ldif 
  
# set directory password
export LDAP_ADMIN_PASSWORD_ENCRYPTED=$(slappasswd -s $LDAP_ADMIN_PASSWORD)

# configure domain
envsubst < ${SCRIPT_DIR}/ldif/domain.ldif.template > ${SCRIPT_DIR}/ldif/domain.ldif 

# configure base domain
envsubst < ${SCRIPT_DIR}/ldif/basedomain.ldif.template > ${SCRIPT_DIR}/ldif/basedomain.ldif 

# start slapd in background
/usr/sbin/slapd -u ldap -g ldap -h 'ldap:/// ldapi:///' &
while [ ! -e /run/openldap/slapd.pid ]; do sleep 1; done

# init ldap directory
ldapadd -Y EXTERNAL -H ldapi:/// -f ${SCRIPT_DIR}/ldif/chrootpw.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f ${SCRIPT_DIR}/ldif/domain.ldif
ldapadd -x -D cn=${LDAP_BIND_CN},${LDAP_BASE_DN} -w ${LDAP_ADMIN_PASSWORD} -f ${SCRIPT_DIR}/ldif/basedomain.ldif

# shut down slapd
SLAPD_PID=$(cat /run/openldap/slapd.pid)
kill -15 $SLAPD_PID
while [ -e /proc/$SLAPD_PID ]; do sleep 1; done # wait until slapd is terminated 