#!/bin/sh -e

# set variables
PROFTPD_VERSION=1.3.8-r3
VERSION=$(echo ${PROFTPD_VERSION} | awk -F- '{print $1}')

# run main script
echo "+----------------------------------------------------------+"
echo "|                                                          |"
echo "|                Welcome to Proftpd Docker!                |"
echo "|                                                          |"
echo "+----------------------------------------------------------+"

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -z "$PASV_ADDRESS" ]; then
  echo "** This container will not run without setting for PASV_ADDRESS **"
  sleep 10
  exit 1
fi

#if [ -e /run/secrets/$FTPUSER_PASSWORD_SECRET ] && ! id -u "$FTPUSER_NAME"; then
#  adduser -u $FTPUSER_UID -s /bin/sh -g "ftp user" -D $FTPUSER_NAME
#  echo "$FTPUSER_NAME:$(cat /run/secrets/$FTPUSER_PASSWORD_SECRET)" \
#    | chpasswd -e
#fi

if [ -e /run/secrets/$FTPUSER_PASSWORD_SECRET ] && ! id -u "$FTPUSER_NAME"; then
   #
   COUNT=$(cat /run/secrets/$FTPUSER_PASSWORD_SECRET | wc -l)
   COUNT=$((${COUNT}+1))

   # create group
   echo ""
   echo -n "Creating ftp group: ${FTPGROUP_NAME}...         "
   addgroup -g ${FTPGROUP_GID} ${FTPGROUP_NAME}
   echo "[ done ]"
   #
   #for ((i=1;i<${COUNT};i++)); do
   for i in $(cat /run/secrets/${FTPUSER_PASSWORD_SECRET}); do
      FTPUSER_NAME=$(cat /run/secrets/${FTPUSER_PASSWORD_SECRET}|grep $i |awk -F : '{print $1}')
      FTPUSER_PASSWORD=$(cat /run/secrets/${FTPUSER_PASSWORD_SECRET} |grep $i |awk -F : '{print $2}')
      echo -n "Creating ftp user: ${FTPUSER_NAME}...          "
      adduser -u ${FTPUSER_UID} -s /bin/sh -g "ftp user" -D ${FTPUSER_NAME} -G ${FTPGROUP_NAME}
      echo "[ done ]"
      echo "${FTPUSER_NAME}:${FTPUSER_PASSWORD}" | chpasswd -e
      FTPUSER_UID=$((${FTPUSER_UID}+1))
      echo ""
   done
fi

mkdir -p /run/proftpd && chown proftpd /run/proftpd/

sed -i \
    -e "s:{{ ALLOW_OVERWRITE }}:$ALLOW_OVERWRITE:" \
    -e "s:{{ ANONYMOUS_DISABLE }}:$ANONYMOUS_DISABLE:" \
    -e "s:{{ ANON_UPLOAD_ENABLE }}:$ANON_UPLOAD_ENABLE:" \
    -e "s:{{ LOCAL_UMASK }}:$LOCAL_UMASK:" \
    -e "s:{{ MAX_CLIENTS }}:$MAX_CLIENTS:" \
    -e "s:{{ MAX_INSTANCES }}:$MAX_INSTANCES:" \
    -e "s:{{ PASV_ADDRESS }}:$PASV_ADDRESS:" \
    -e "s:{{ PASV_MAX_PORT }}:$PASV_MAX_PORT:" \
    -e "s:{{ PASV_MIN_PORT }}:$PASV_MIN_PORT:" \
    -e "s+{{ SERVER_NAME }}+$SERVER_NAME+" \
    -e "s:{{ TIMES_GMT }}:$TIMES_GMT:" \
    -e "s:{{ WRITE_ENABLE }}:$WRITE_ENABLE:" \
    -e "s:{{ FTPGROUP_NAME }}:$FTPGROUP_NAME:" \
    /etc/proftpd/proftpd.conf

# add LDAP config
if [[ ${LDAP_MODULE} = true ]]; then
   echo ""
   echo -n "Creating file \"ldap.conf\"...            "
   sed -i \
       -e "s|{{ LDAP_SERVER }}|${LDAP_SERVER}|" \
       -e "s|{{ LDAP_BIND_DN }}|${LDAP_BIND_DN}|" \
       -e "s|{{ LDAP_BIND_DN_PASSWORD }}|${LDAP_BIND_DN_PASSWORD}|" \
       -e "s|{{ LDAP_USERS }}|${LDAP_USERS}|" \
       -e "s|{{ LDAP_GROUPS }}|${LDAP_GROUPS}|" \
       -e "s|{{ FTPGROUP_GID }}|${FTPGROUP_GID}|" \
       /etc/proftpd/conf.d/ldap.conf
   echo "[ done ]"

   echo -n "Adding AuthOrder into \"proftpd.conf\"... "
   sed -i -e "/Umask/a\ \n# Authentication\nAuthOrder               mod_ldap.c mod_auth_unix.c" \
       /etc/proftpd/proftpd.conf
   echo "[ done ]"
   echo ""
   
   echo -n "Commenting \"DenyGroup\"...               "
   sed -i -e "s|DenyGroup !${FTPGROUP_NAME}|#DenyGroup !${FTPGROUP_NAME} |" \
       /etc/proftpd/proftpd.conf
   echo "[ done ]"
   echo ""
else
   echo ""
   echo -n "Removing file \"ldap.conf\"... "
   rm -rf /etc/proftpd/conf.d/ldap.conf
   echo "[ done ]"
   echo ""
fi

echo "+----------------------------------------------------------+"
echo "|                 OK, prepare finshed ;-)                  |"
echo "|                                                          |"
echo "|              Starting Proftpd Version ${VERSION} ...          |"
echo "+----------------------------------------------------------+"
echo

exec proftpd --nodaemon -c /etc/proftpd/proftpd.conf
