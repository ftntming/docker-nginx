#!/bin/bash
set -e

install_packages() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

download_and_extract() {
  src=${1}
  dest=${2}
  tarball=$(basename ${src})

  if [[ ! -f ${NGINX_BUILD_ASSETS_DIR}/${tarball} ]]; then
    echo "Downloading ${1}..."
    wget ${src} -O ${NGINX_BUILD_ASSETS_DIR}/${tarball}
  fi

  echo "Extracting ${tarball}..."
  mkdir ${dest}
  tar xf ${NGINX_BUILD_ASSETS_DIR}/${tarball} --strip=1 -C ${dest}
}

strip_debug() {
  local dir=${1}
  local filter=${2}
  for f in $(find "${dir}" -name "${filter}")
  do
    if [[ -f ${f} ]]; then
      strip --strip-all ${f}
    fi
  done
}
#
#${WITH_RTMP} && {
#  download_and_extract "http://prdownloads.sourceforge.net/opencore-amr/fdk-aac-${FDK_AAC_VERSION}.tar.gz" "${NGINX_BUILD_ASSETS_DIR}/fdk-aac"
#  cd ${NGINX_BUILD_ASSETS_DIR}/fdk-aac
#  ./configure \
#    --prefix=/usr \
#    --enable-shared \
#    --disable-static \
#    --disable-example
#  make -j$(nproc)
#  make install
#  make DESTDIR=${NGINX_BUILD_ROOT_DIR} install
#
#  install_packages nasm
#  download_and_extract "http://ftp.videolan.org/pub/x264/snapshots/x264-${X264_VERSION}.tar.bz2" "${NGINX_BUILD_ASSETS_DIR}/x264"
#  cd ${NGINX_BUILD_ASSETS_DIR}/x264
#  ./configure \
#    --prefix=/usr \
#    --enable-shared \
#    --disable-opencl
#  make -j$(nproc)
#  make install
#  make DESTDIR=${NGINX_BUILD_ROOT_DIR} install
#
#  download_and_extract "https://libav.org/releases/libav-${LIBAV_VERSION}.tar.gz" "${NGINX_BUILD_ASSETS_DIR}/libav"
#  cd ${NGINX_BUILD_ASSETS_DIR}/libav
#  ./configure \
#    --prefix=/usr \
#    --disable-debug \
#    --disable-static \
#    --enable-shared \
#    --enable-nonfree \
#    --enable-gpl \
#    --enable-libx264 \
#    --enable-libfdk-aac
#  make -j$(nproc)
#  make DESTDIR=${NGINX_BUILD_ROOT_DIR} install
#
#  download_and_extract "https://github.com/arut/nginx-rtmp-module/archive/v${RTMP_VERSION}.tar.gz" ${NGINX_BUILD_ASSETS_DIR}/nginx-rtmp-module
#  EXTRA_ARGS+=" --add-module=${NGINX_BUILD_ASSETS_DIR}/nginx-rtmp-module"
#}
#
#${WITH_PAGESPEED} && {
#  download_and_extract "https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}-stable.tar.gz" ${NGINX_BUILD_ASSETS_DIR}/ngx_pagespeed
#  download_and_extract "https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}-x64.tar.gz" ${NGINX_BUILD_ASSETS_DIR}/ngx_pagespeed/psol
#  EXTRA_ARGS+=" --add-module=${NGINX_BUILD_ASSETS_DIR}/ngx_pagespeed"
#}

#
# download_and_extract "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" ${NGINX_BUILD_ASSETS_DIR}/nginx
# download_and_extract "https://github.com/ftntming/nginx-xmpp/archive/v1.7.9.tar.gz" ${NGINX_BUILD_ASSETS_DIR}/nginx
install_packages git make curl

# SSL
# (single command that will download latest binaries, extract them, cd into the directory, compile configuration and then install the files)
curl https://www.openssl.org/source/openssl-1.0.2l.tar.gz | tar xz && cd openssl-1.0.2l && ./config && make && make install
pwd
# (This will create a sym link to the new binaries)
ln -sf /usr/local/ssl/bin/openssl `which openssl`
# (Used to check the version of the Current OpenSSL binaries)
openssl version -v

git clone https://github.com/ftntming/nginx-xmpp -b 1.9.10-xmpp ${NGINX_BUILD_ASSETS_DIR}/nginx
cd ${NGINX_BUILD_ASSETS_DIR}/nginx
# install_packages libpcre++-dev libssl-dev zlib1g-dev libxslt1-dev libgd-dev libgeoip-dev uuid-dev
install_packages libpcre++-dev zlib1g-dev libxslt1-dev libgd-dev libgeoip-dev uuid-dev
${NGINX_BUILD_ASSETS_DIR}/nginx/auto/configure --with-mail --with-mail_ssl_module --with-openssl=/openssl-1.0.2l
sed -i 's/-Werror//g' ${NGINX_BUILD_ASSETS_DIR}/nginx/objs/Makefile
make -j$(nproc)
make DESTDIR=${NGINX_BUILD_ROOT_DIR} install

# install default configuration
#mkdir -p ${NGINX_BUILD_ROOT_DIR}/etc/nginx
#cp -rf ${NGINX_BUILD_ASSETS_DIR}/config/* ${NGINX_BUILD_ROOT_DIR}/etc/nginx/

