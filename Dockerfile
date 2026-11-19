FROM jlesage/baseimage-gui:ubuntu-24.04-v4

COPY --chmod=775 startapp.sh /startapp.sh
ADD https://raw.githubusercontent.com/nextcloud/vm/refs/heads/main/static/fetch_lib.sh /var/scripts/fetch_lib.sh
ADD https://raw.githubusercontent.com/nextcloud/vm/main/lib.sh /var/scripts/lib.sh
ADD https://patch-diff.githubusercontent.com/raw/szaimen/vm/pull/1.patch /smbserver.patch
ADD https://raw.githubusercontent.com/nextcloud/vm/refs/heads/main/not-supported/smbserver.sh /smbserver.sh
COPY supervisord.conf /supervisord.conf

# Set the name of the application.
RUN set-cont-env APP_NAME "Nextcloud AIO SMB Server"

ENV USER_ID=0 \
    GROUP_ID=0 \
    WEB_AUTHENTICATION=1 \
    SECURE_CONNECTION=1 \
    WEB_LISTENING_PORT=5803

# hadolint ignore=DL3008,DL3003
RUN set -ex; \
    # /var/log is a symlink to /config/log in the base image, which does not exist at build time
    mkdir -p /config/log; \
    apt-get update; \
    apt-get upgrade -y; \
    rm -rf /var/lib/apt/lists/*; \
    \
    add-pkg \
        whiptail \
        samba \
        curl \
        xterm \
        lsb-release \
        iproute2 \
        adduser \
        git \
        supervisor \
        rsync \
        samba-vfs-modules \
    ; \
    chmod +x /startapp.sh; \
    cd /; \
    sed -i 's|not-supported/||g' /smbserver.patch; \
    git apply /smbserver.patch; \
    rm -rf /config/log

VOLUME /smbserver

# Needed for Nextcloud AIO so that image cleanup can work. 
# Unfortunately, this needs to be set in the Dockerfile in order to work.
LABEL org.label-schema.vendor="Nextcloud"
