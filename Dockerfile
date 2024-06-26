FROM alpine:3.20
    
ARG BUILD_DATE

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name=proftpd \
      org.label-schema.authors="Johann H." \
      org.label-schema.description="FTP Server"

# PKG URL: https://pkgs.alpinelinux.org/packages?page=7&branch=edge&name=proft%2A
# set variables 
ARG PROFTPD_VERSION=1.3.8b-r2
ENV ALLOW_OVERWRITE=on \
    ANONYMOUS_DISABLE=off \
    ANON_UPLOAD_ENABLE=DenyAll \
    FTPUSER_PASSWORD_SECRET=ftp-user-password \
    FTPUSER_NAME=${FTPUSER_NAME:-ftpuser} \
    FTPUSER_UID=${FTPUSER_UID:-1001} \
    FTPGROUP_GID=${FTPGROUP_GID:-5001} \
    FTPGROUP_NAME=${FTPGROUP_NAME:-ftpusers} \
    LOCAL_UMASK=022 \
    MAX_CLIENTS=10 \
    MAX_INSTANCES=30 \
    PASV_ADDRESS= \
    PASV_MIN_PORT=30091 \
    PASV_MAX_PORT=30100 \
    SERVER_NAME=ProFTPD \
    TIMES_GMT=off \
    TZ=UTC \
    WRITE_ENABLE=AllowAll \
    # set true|false
    LDAP_MODULE=false \
    LDAP_SERVER= \
    LDAP_BIND_DN= \
    LDAP_BIND_DN_PASSWORD= \
    LDAP_USERS= \
    LDAP_GROUPS=


#COPY /rootfs/etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf
COPY rootfs/ /
RUN chmod 644 /etc/proftpd/proftpd.conf \
    && apk --no-cache  add  --update \
       #libcrypto1.1 \
       libcrypto3 \
       proftpd=$PROFTPD_VERSION \
       proftpd-mod_tls \
       proftpd-mod_ldap \
       tzdata \
    && rm -rf /var/cache/apk/* 

VOLUME /etc/proftpd/conf.d /etc/proftpd/modules.d /var/lib/ftp
EXPOSE 21 $PASV_MIN_PORT-$PASV_MAX_PORT

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
