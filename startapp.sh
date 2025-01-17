#!/bin/bash

if ! [ -f /smbserver/group ]; then
    groupadd -g 33 www-data
fi
if ! [ -f /smbserver/shadow ]; then
    adduser --no-create-home --quiet --uid 33 --gid 33 --disabled-login --force-badname --gecos www-data www-data
fi
if [ -d /smbserver/samba ]; then
    cp -prf /smbserver/samba /etc/samba 
fi

backup_important_files() {
    set -x
    rm -f /smbserver/group
    cp -p /etc/group /smbserver/group
    rm -f /smbserver/shadow
    cp -p /etc/shadow /smbserver/shadow 
    rm -rf /smbserver/samba
    cp -pr /etc/samba /smbserver/samba
    set +x
}

# Catch docker stop attempts
trap backup_important_files SIGINT SIGTERM

exec /usr/bin/supervisord -c /supervisord.conf &
exec xterm &
wait $!
