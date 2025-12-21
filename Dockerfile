FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

ARG BUILD_DATE
ARG VERSION

LABEL build_version="version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="Joly0"

ENV TITLE=Pinokio
ENV PINOKIO_SHARE_LOCAL=true
ENV PINOKIO_SHARE_LOCAL_PORT=50000

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    dbus \
    dbus-x11 \
    firefox-esr \
    jq \
  && \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/Joly0/docker-templates/refs/heads/main/icons/pinokio-logo_small.png && \
  echo "**** install pinokio studio from deb ****" && \
  # decide which release JSON to fetch
  if [ -z "${PINOKIO_VERSION:-}" ]; then \
    echo "No PINOKIO_VERSION provided, using latest release"; \
    RELEASE_URL="https://api.github.com/repos/pinokiocomputer/pinokio/releases/latest"; \
  else \
    echo "Using specified PINOKIO_VERSION: ${PINOKIO_VERSION}"; \
    RELEASE_URL="https://api.github.com/repos/pinokiocomputer/pinokio/releases/tags/${PINOKIO_VERSION}"; \
  fi && \
  # fetch release JSON once into a file
  curl -sS "$RELEASE_URL" -o /tmp/release.json && \
  resolved_tag="$(jq -r '.tag_name' /tmp/release.json)" && \
  echo "Resolved release tag: ${resolved_tag}" && \
  # pick the .deb URL for x86_64/amd64 (exclude arm64 builds)
  download_url="$(jq -r '.assets[] | select(.name | (endswith(".deb") and (contains("-arm64.") | not))) | .browser_download_url' /tmp/release.json | head -n 1)" && \
  # fallback: any .deb if the above did not find a match
  if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then \
    echo "No x86_64-specific .deb found, falling back to any .deb"; \
    download_url="$(jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' /tmp/release.json | head -n 1)"; \
  fi && \
  if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then \
    echo "ERROR: Could not determine a Pinokio .deb download URL" >&2; \
    exit 1; \
  fi && \
  echo "Downloading .deb from: $download_url" && \
  cd /tmp && \
  curl -L -o /tmp/pinokio.deb "$download_url" && \
  chmod +x /tmp/pinokio.deb && \
  apt install --no-install-recommends -y ./pinokio.deb && \
  find /opt/Pinokio -type d -exec chmod go+rx {} + && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY /root /

EXPOSE 3001

VOLUME /config