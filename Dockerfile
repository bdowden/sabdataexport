FROM ghcr.io/linuxserver/baseimage-alpine:3.14

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BAZARR_VERSION
LABEL build_version="Dowdentech version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="bdowden"
# hard set UTC in case the user does not define it
ENV TZ="Etc/UTC"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    cargo \
    g++ \
    gcc \
    jq \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    python3-dev && \
  echo "**** install packages ****" && \
  apk add --no-cache \
    curl \
    libxml2 \
    libxslt \
    py3-pip \
    python3 && \
  echo "**** install sabnzbd exporter ****" && \
  if [ -z ${SABEXPORTER_VERSION+x} ]; then \
    SABEXPORTER_VERSION=$(curl -sX GET "https://api.github.com/repos/msroest/sabnzbd_exporter/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/sabnzbdexport.zip -L \
    "https://github.com/msroest/sabnzbd_exporter/releases/download/${SABEXPORTER_VERSION}/sabnzbdexport.zip" && \
  mkdir -p \
    /app/sabnzbdexport/bin && \
  unzip \
    /tmp/sabnzbdexport.zip -d \
    /app/sabnzbdexport/bin && \
  rm -Rf /app/sabnzbdexport/bin/bin && \
  echo "UpdateMethod=docker\nBranch=master\nPackageVersion=${VERSION}\nPackageAuthor=[dowdentech](https://dowdentech.com)" > /app/sabnzbdexport/package_info && \
  echo "**** Install requirements ****" && \
  pip3 install -U --no-cache-dir pip && \
  pip install lxml --no-binary :all: && \
  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine/  -r \
    /app/sabnzbdexport/bin/requirements.txt && \
  echo "**** clean up ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /root/.cargo \
    /tmp/*

# add local files
COPY root/ /

# ports and volumes
VOLUME /config