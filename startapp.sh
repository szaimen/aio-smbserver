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
if [ -f /smbserver/passdb.tdb ]; then
    cp -pf /smbserver/passdb.tdb /var/lib/samba/private/passdb.tdb
fi
if [ -d /smbserver/samba ]; then
    rsync -a --delete /smbserver/samba/ /etc/samba/ 
fi
# Never fall back to guest access for an unknown/bad Windows account.
# The distro-packaged Samba default ("map to guest = bad user") makes smbd
# attempt a guest session instead of cleanly rejecting the connection. That
# guest-session setup crashes smbd (NT_STATUS_CONNECTION_RESET) instead of
# returning a clean auth failure, so Windows clients never see a
# credentials prompt and just get a generic network error (0x80004005).
if [ -f /etc/samba/smb.conf ]; then
    if grep -q "map to guest =" /etc/samba/smb.conf; then
        sed -i 's|.*map to guest =.*|   map to guest = never|' /etc/samba/smb.conf
    else
        sed -i '/\[global\]/a map to guest = never' /etc/samba/smb.conf
    fi
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
    rm -f /smbserver/passdb.tdb
    cp -p /var/lib/samba/private/passdb.tdb /smbserver/passdb.tdb
    mkdir -p /smbserver/samba/
    rsync -a --delete /etc/samba/ /smbserver/samba/
    set +x
}

# Catch docker stop attempts
trap backup_important_files SIGINT SIGTERM

exec /usr/bin/supervisord -c /supervisord.conf &
exec xterm &
wait $!
