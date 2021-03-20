FROM ubuntu:bionic-20190612 AS builder

ENV RTMP_VERSION=1.2.1 \
    NPS_VERSION=1.13.35.2  \
    FDK_AAC_VERSION=0.1.6 \
    X264_VERSION=snapshot-20180720-2245-stable \
    LIBAV_VERSION=12.3 \
    NGINX_VERSION=1.15.12 \
    NGINX_BUILD_ASSETS_DIR=/var/lib/docker-nginx \
    NGINX_BUILD_ROOT_DIR=/var/lib/docker-nginx/rootfs

ARG WITH_DEBUG=false

ARG WITH_PAGESPEED=true

ARG WITH_RTMP=true

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      wget ca-certificates make gcc g++ pkg-config

# Copy nginx-xmpp from src instead of geting it from github
COPY nginx-xmpp ${NGINX_BUILD_ASSETS_DIR}/nginx

COPY assets/build/install.sh ${NGINX_BUILD_ASSETS_DIR}/install.sh

RUN chmod +x ${NGINX_BUILD_ASSETS_DIR}/install.sh

RUN ${NGINX_BUILD_ASSETS_DIR}/install.sh

COPY assets/build/config ${NGINX_BUILD_ROOT_DIR}/etc/nginx/

COPY entrypoint.sh ${NGINX_BUILD_ROOT_DIR}/sbin/entrypoint.sh

RUN chmod 755 ${NGINX_BUILD_ROOT_DIR}/sbin/entrypoint.sh

FROM ubuntu:bionic-20190612

LABEL maintainer="sameer@damagehead.com"

ENV NGINX_USER=www-data \
    NGINX_SITECONF_DIR=/etc/nginx/sites-enabled \
    NGINX_LOG_DIR=/var/log/nginx \
    NGINX_TEMP_DIR=/var/lib/nginx

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      libssl1.1 libxslt1.1 libgd3 libgeoip1 libfdk-aac1 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /var/lib/docker-nginx/rootfs /

COPY assets/build/config /etc/nginx/

EXPOSE 80/tcp 443/tcp 1935/tcp

ENTRYPOINT ["/sbin/entrypoint.sh"]

CMD ["/usr/local/nginx/sbin/nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
