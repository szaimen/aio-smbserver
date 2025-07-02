FROM jlesage/baseimage-gui:ubuntu-24.04-v4

COPY --chmod=775 startapp.sh /startapp.sh
ADD https://raw.githubusercontent.com/nextcloud/vm/refs/heads/main/static/fetch_lib.sh /var/scripts/fetch_lib.sh
ADD https://raw.githubusercontent.com/nextcloud/vm/main/lib.sh /var/scripts/lib.sh
ADD https://patch-diff.githubusercontent.com/raw/szaimen/vm/pull/1.patch /smbserver.patch
ADD https://raw.githubusercontent.com/nextcloud/vm/refs/heads/main/not-supported/smbserver.sh /smbserver.sh
COPY supervisord.conf /supervisord.conf

# Set the name of the application.
RUN set-cont-env APP_NAME "Nextcloud AIO SMB Server"

# hadolint ignore=DL3002
USER root

ENV USER_ID=0 \
    GROUP_ID=0 \
    WEB_AUTHENTICATION=1 \
    SECURE_CONNECTION=1 \
    WEB_LISTENING_PORT=5803

# hadolint ignore=DL3008,DL3003
RUN set -ex; \
    \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
        whiptail \
        samba \
        cpuid \
        curl \
        xterm \
        lsb-release \
        iproute2 \
        adduser \
        git \
        supervisor \
        rsync \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    chmod +x /startapp.sh; \
    mkdir -p /var/log/supervisord /var/run/supervisord; \
    cd /; \
    sed -i 's|not-supported/||g' /smbserver.patch; \
    git apply /smbserver.patch

VOLUME /smbserver

# Needed for Nextcloud AIO so that image cleanup can work. 
# Unfortunately, this needs to be set in the Dockerfile in order to work.
LABEL org.label-schema.vendor="Nextcloud"
