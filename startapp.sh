#!/bin/bash

set -x
if ! [ -f /smbserver/group ]; then
    groupadd -g 33 www-data
    groupadd -g 65534 nobody
    groupadd users
else
    cp -pf /smbserver/group /etc/group
fi
if ! [ -f /smbserver/shadow ] || ! [ -f /smbserver/passwd ]; then
    adduser --no-create-home --quiet --uid 33 --gid 33 --disabled-login --force-badname --gecos www-data www-data
    adduser --no-create-home --quiet --uid 65534 --gid 65534 --disabled-login --force-badname --gecos nobody nobody
else
    cp -pf /smbserver/shadow /etc/shadow
    cp -pf /smbserver/passwd /etc/passwd
fi
if [ -d /smbserver/samba ]; then
    rsync -a --delete /smbserver/samba/ /etc/samba/ 
fi
set +x

backup_important_files() {
    set -x
    rm -f /smbserver/group
    cp -p /etc/group /smbserver/group
    rm -f /smbserver/shadow
    cp -p /etc/shadow /smbserver/shadow 
    rm -f /smbserver/passwd
    cp -p /etc/passwd /smbserver/passwd 
    mkdir -p /smbserver/samba/
    rsync -a --delete /etc/samba/ /smbserver/samba/
    set +x
}

# Catch docker stop attempts
trap backup_important_files SIGINT SIGTERM

exec /usr/bin/supervisord -c /supervisord.conf &
exec xterm &
wait $!
