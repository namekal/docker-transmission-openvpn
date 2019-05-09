FROM lsiobase/ubuntu:xenial

# set version label
ARG BUILD_DATE
ARG VERSION
ARG SABNZBD_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="namekal"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

VOLUME /config /downloads

RUN \
 apt-get update && apt-get upgrade -y && \
 apt-get install -y \
    wget \
    curl \
    sudo \
    unzip \
    zip \
    jq \
    git \
    software-properties-common
RUN \
apt-get update && \
 add-apt-repository ppa:transmissionbt/ppa && \
 wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - && \
 echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" > /etc/apt/sources.list.d/openvpn-aptrepo.list && \
 apt update && \
 apt-get install -y transmission-cli transmission-common transmission-daemon bc \
 openvpn \
 python2.7 python2.7-pysqlite2 && ln -sf /usr/bin/python2.7 /usr/bin/python2

RUN \
 wget https://github.com/Secretmapper/combustion/archive/release.zip \
    && unzip release.zip -d /opt/transmission-ui/ \
    && rm release.zip \
    && mkdir /opt/transmission-ui/transmission-web-control \
    && curl -sL `curl -s https://api.github.com/repos/ronggang/transmission-web-control/releases/latest | jq --raw-output '.tarball_url'` | tar -C /opt/transmission-ui/transmission-web-control/ --strip-components=2 -xz \
    && ln -s /usr/share/transmission/web/style /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/images /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/javascript /opt/transmission-ui/transmission-web-control \
    && ln -s /usr/share/transmission/web/index.html /opt/transmission-ui/transmission-web-control/index.original.html \
    && git clone git://github.com/endor/kettu.git /opt/transmission-ui/kettu

RUN \
 echo "***** add sabnzbd repositories ****" && \
 apt-key adv --keyserver hkp://keyserver.ubuntu.com:11371 --recv-keys 0x98703123E0F52B2BE16D586EF13930B14BB9F05F && \
 echo "deb http://ppa.launchpad.net/jcfp/nobetas/ubuntu xenial main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 echo "deb-src http://ppa.launchpad.net/jcfp/nobetas/ubuntu xenial main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 echo "deb http://ppa.launchpad.net/jcfp/sab-addons/ubuntu xenial main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 echo "deb-src http://ppa.launchpad.net/jcfp/sab-addons/ubuntu xenial main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 echo "**** install packages ****" && \
 if [ -z ${SABNZBD_VERSION+x} ]; then \
    SABNZBD="sabnzbdplus"; \
 else \
    SABNZBD="sabnzbdplus=${SABNZBD_VERSION}"; \
 fi && \
 apt-get update && \
 add-apt-repository multiverse && \
 apt-get update && \
 apt-get install -y \
    p7zip-full \
    par2-tbb \
    python-sabyenc \
    ${SABNZBD} \
    unrar \
    ufw \
    iputils-ping && \
 wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb && \
 dpkg -i dumb-init*.deb && \
 rm -rf dumb-init*.deb && \
 curl -L https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz | tar -C /usr/local/bin -xzv && \
 printf "USER=root\nHOST=0.0.0.0\nPORT=8081\nCONFIG=/config/sabnzbd-home\nX_FRAME_OPTIONS=0\n" > /etc/default/sabnzbdplus && \
 echo "**** cleanup ****" && \
 apt-get clean && \
 rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* && \
 service sabnzbdplus start

COPY root/ /

ADD openvpn/ /etc/openvpn/
ADD transmission/ /etc/transmission/
ADD scripts /etc/scripts/

ENV \
    OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** \
    GLOBAL_APPLY_PERMISSIONS=true \
    TRANSMISSION_ALT_SPEED_DOWN=50 \
    TRANSMISSION_ALT_SPEED_ENABLED=false \
    TRANSMISSION_ALT_SPEED_TIME_BEGIN=540 \
    TRANSMISSION_ALT_SPEED_TIME_DAY=127 \
    TRANSMISSION_ALT_SPEED_TIME_ENABLED=false \
    TRANSMISSION_ALT_SPEED_TIME_END=1020 \
    TRANSMISSION_ALT_SPEED_UP=1 \
    TRANSMISSION_BIND_ADDRESS_IPV4=0.0.0.0 \
    TRANSMISSION_BIND_ADDRESS_IPV6=:: \
    TRANSMISSION_BLOCKLIST_ENABLED=false \
    TRANSMISSION_BLOCKLIST_URL=http://www.example.com/blocklist \
    TRANSMISSION_CACHE_SIZE_MB=4 \
    TRANSMISSION_DHT_ENABLED=true \
    TRANSMISSION_DOWNLOAD_DIR=/downloads/complete \
    TRANSMISSION_DOWNLOAD_LIMIT=100 \
    TRANSMISSION_DOWNLOAD_LIMIT_ENABLED=0 \
    TRANSMISSION_DOWNLOAD_QUEUE_ENABLED=true \
    TRANSMISSION_DOWNLOAD_QUEUE_SIZE=5 \
    TRANSMISSION_ENCRYPTION=1 \
    TRANSMISSION_IDLE_SEEDING_LIMIT=30 \
    TRANSMISSION_IDLE_SEEDING_LIMIT_ENABLED=false \
    TRANSMISSION_INCOMPLETE_DIR=/downloads/incomplete \
    TRANSMISSION_INCOMPLETE_DIR_ENABLED=true \
    TRANSMISSION_LPD_ENABLED=false \
    TRANSMISSION_MAX_PEERS_GLOBAL=200 \
    TRANSMISSION_MESSAGE_LEVEL=2 \
    TRANSMISSION_PEER_CONGESTION_ALGORITHM= \
    TRANSMISSION_PEER_ID_TTL_HOURS=6 \
    TRANSMISSION_PEER_LIMIT_GLOBAL=200 \
    TRANSMISSION_PEER_LIMIT_PER_TORRENT=50 \
    TRANSMISSION_PEER_PORT=51413 \
    TRANSMISSION_PEER_PORT_RANDOM_HIGH=65535 \
    TRANSMISSION_PEER_PORT_RANDOM_LOW=49152 \
    TRANSMISSION_PEER_PORT_RANDOM_ON_START=false \
    TRANSMISSION_PEER_SOCKET_TOS=default \
    TRANSMISSION_PEX_ENABLED=true \
    TRANSMISSION_PORT_FORWARDING_ENABLED=false \
    TRANSMISSION_PREALLOCATION=1 \
    TRANSMISSION_PREFETCH_ENABLED=1 \
    TRANSMISSION_QUEUE_STALLED_ENABLED=true \
    TRANSMISSION_QUEUE_STALLED_MINUTES=30 \
    TRANSMISSION_RATIO_LIMIT=2 \
    TRANSMISSION_RATIO_LIMIT_ENABLED=false \
    TRANSMISSION_RENAME_PARTIAL_FILES=true \
    TRANSMISSION_RPC_AUTHENTICATION_REQUIRED=false \
    TRANSMISSION_RPC_BIND_ADDRESS=0.0.0.0 \
    TRANSMISSION_RPC_ENABLED=true \
    TRANSMISSION_RPC_HOST_WHITELIST= \
    TRANSMISSION_RPC_HOST_WHITELIST_ENABLED=false \
    TRANSMISSION_RPC_PASSWORD=password \
    TRANSMISSION_RPC_PORT=9091 \
    TRANSMISSION_RPC_URL=/transmission/ \
    TRANSMISSION_RPC_USERNAME=username \
    TRANSMISSION_RPC_WHITELIST=127.0.0.1 \
    TRANSMISSION_RPC_WHITELIST_ENABLED=false \
    TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED=true \
    TRANSMISSION_SCRIPT_TORRENT_DONE_ENABLED=true \
    TRANSMISSION_SCRIPT_TORRENT_DONE_FILENAME="/etc/transmission/unrar.sh" \
    TRANSMISSION_SEED_QUEUE_ENABLED=false \
    TRANSMISSION_SEED_QUEUE_SIZE=10 \
    TRANSMISSION_SPEED_LIMIT_DOWN=100 \
    TRANSMISSION_SPEED_LIMIT_DOWN_ENABLED=false \
    TRANSMISSION_SPEED_LIMIT_UP=100 \
    TRANSMISSION_SPEED_LIMIT_UP_ENABLED=false \
    TRANSMISSION_START_ADDED_TORRENTS=true \
    TRANSMISSION_TRASH_ORIGINAL_TORRENT_FILES=false \
    TRANSMISSION_UMASK=2 \
    TRANSMISSION_UPLOAD_LIMIT=100 \
    TRANSMISSION_UPLOAD_LIMIT_ENABLED=0 \
    TRANSMISSION_UPLOAD_SLOTS_PER_TORRENT=14 \
    TRANSMISSION_UTP_ENABLED=true \
    TRANSMISSION_WATCH_DIR=/config/watch \
    TRANSMISSION_WATCH_DIR_ENABLED=true \
    TRANSMISSION_HOME=/config/transmission-home \
    TRANSMISSION_WATCH_DIR_FORCE_GENERIC=false \
    ENABLE_UFW=false \
    UFW_ALLOW_GW_NET=false \
    UFW_EXTRA_PORTS= \
    UFW_DISABLE_IPTABLES_REJECT=false \
    TRANSMISSION_WEB_UI= \
    PUID= \
    PGID= \
    TRANSMISSION_WEB_HOME= \
    DROP_DEFAULT_ROUTE= \
    WEBPROXY_ENABLED=false \
    WEBPROXY_PORT=8888 \
    HEALTH_CHECK_HOST=google.com

# add local files

HEALTHCHECK --interval=5m CMD /etc/scripts/healthcheck.sh

# ports and volumes
EXPOSE 8081 9090 9091

CMD ["dumb-init", "/etc/openvpn/start.sh"]