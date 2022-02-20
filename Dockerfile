# syntax = docker/dockerfile:1.3

FROM eclipse-temurin:17-jdk

# CI system should set this to a hash or git revision of the build directory and it's contents to
# ensure consistent cache updates.
ARG BUILD_FILES_REV=1
RUN --mount=target=/docker/build,source=docker/build \
    REV=${BUILD_FILES_REV} /build/run.sh install-packages

RUN --mount=target=/docker/build,source=docker/build \
    REV=${BUILD_FILES_REV} /build/run.sh setup-user

COPY --chmod=644 docker/files/sudoers* /etc/sudoers.d

EXPOSE 25565 25575

VOLUME ["/data"]
WORKDIR /data

STOPSIGNAL SIGTERM

ENV UID=1000 GID=1000 \
  MEMORY="2G" \
  TYPE=AIRPLANE VERSION=LATEST \
  ENABLE_RCON=true RCON_PORT=25575 RCON_PASSWORD=minecraft \
  ENABLE_AUTOPAUSE=false AUTOPAUSE_TIMEOUT_EST=3600 AUTOPAUSE_TIMEOUT_KN=120 AUTOPAUSE_TIMEOUT_INIT=600 \
  AUTOPAUSE_PERIOD=10 AUTOPAUSE_KNOCK_INTERFACE=eth0 \
  ENABLE_AUTOSTOP=false AUTOSTOP_TIMEOUT_EST=3600 AUTOSTOP_TIMEOUT_INIT=1800 AUTOSTOP_PERIOD=10

COPY --chmod=755 docker/scripts/start* /
COPY --chmod=755 docker/bin/ /usr/local/bin/
COPY --chmod=755 docker/bin/mc-health /health.sh
COPY --chmod=644 docker/files/server.properties /tmp/server.properties
COPY --chmod=644 docker/files/log4j2.xml /tmp/log4j2.xml
COPY --chmod=755 docker/files/autopause /autopause
COPY --chmod=755 docker/files/autostop /autostop

RUN dos2unix /start* /autopause/* /autostop/*

ENTRYPOINT [ "/start" ]
HEALTHCHECK --start-period=1m CMD mc-health
