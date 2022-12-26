#!/bin/sh -e

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
   #
   #for ((i=1;i<${COUNT};i++)); do
   for i in $(cat /run/secrets/${FTPUSER_PASSWORD_SECRET}); do
      FTPUSER_NAME=$(cat /run/secrets/${FTPUSER_PASSWORD_SECRET}|grep $i |awk -F : '{print $1}')
      FTPUSER_PASSWORD=$(cat /run/secrets/${FTPUSER_PASSWORD_SECRET} |grep $i |awk -F : '{print $2}')
      echo -n "Creatnge ftp user: ${FTPUSER_NAME} ..."
      adduser -u ${FTPUSER_UID} -s /bin/sh -g "ftp user" -D ${FTPUSER_NAME} -G ftp
      echo "[ done ]"
      echo "${FTPUSER_NAME}:${FTPUSER_PASSWORD}" | chpasswd -e
      FTPUSER_UID=$((${FTPUSER_UID}+1))
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
    /etc/proftpd/proftpd.conf

exec proftpd --nodaemon -c /etc/proftpd/proftpd.conf
