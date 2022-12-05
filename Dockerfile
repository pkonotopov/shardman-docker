FROM ubuntu:20.04

LABEL shardman_build=14.6.1
ARG PG_MAJOR=14
ARG PGHOME=/var/lib/pgpro
ARG LC_ALL=C.UTF-8
ARG LANG=C.UTF-8
ARG CLUSTER_NAME=cluster0

ENV PG_MAJOR=${PG_MAJOR}
ENV CLUSTER_NAME=${CLUSTER_NAME}

ENV PGDATA="/var/lib/pgpro/sdm-${PG_MAJOR}/data" \
    PATH="/opt/pgpro/sdm-${PG_MAJOR}/bin:${PATH}" \
    DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN ulimit -s unlimited \
    && printf "APT::Install-Recommends '0';\nAPT::Install-Suggests '0';" > /etc/apt/apt.conf.d/01norecommend \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends gnupg curl ca-certificates \
    && printf "deb [arch=amd64] http://repo.postgrespro.ru/pgprosm-14/ubuntu/ focal main" > /etc/apt/sources.list.d/shardman.list \
    && curl -fsSL http://repo.postgrespro.ru/pgprosm-14/keys/GPG-KEY-POSTGRESPRO | apt-key add - \
    # For local builds only
    # && printf "deb [arch=amd64] http://repo.l.postgrespro.ru//pgprosm-14/ubuntu/ focal main" > /etc/apt/sources.list.d/shardman.list \
    # && curl -fsSL http://repo.l.postgrespro.ru/keys/GPG-KEY-POSTGRESPRO | apt-key add - \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    systemd-sysv libicu66 libev4 libpam0g libssl1.1 libxml2 tzdata \
    ssl-cert locales dbus-x11 libipc-run-perl \
    libreadline8 pkg-config zlib1g \
    postgrespro-sdm-${PG_MAJOR}-server \
    postgrespro-sdm-${PG_MAJOR}-client \
    postgrespro-sdm-${PG_MAJOR}-contrib \
    postgrespro-sdm-${PG_MAJOR}-libs \
    postgrespro-sdm-${PG_MAJOR}-backup-src \
    shardman-services \
    shardman-tools \
    stolon-sdm \
    && mkdir -p /etc/systemd/system/systemd-logind.service.d /etc/shardman \
    && chown postgres:postgres /etc/shardman -R \
    && sed -i 's/var\/lib\/pgpro\/sdm-14\/data/etc\/shardman/g' /usr/lib/systemd/system/shardmand\@.service \
    && systemctl enable shardmand@${CLUSTER_NAME} \
    && apt-get purge -y --allow-remove-essential --allow-change-held-packages \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    /root/.cache \
    /var/cache/debconf/* \
    /usr/share/doc* \
    /usr/share/man \
    /tmp/*.deb \
    && find /var/log -type f -exec truncate --size 0 {} \;

ENV PATH "/opt/pgpro/sdm-$PG_MAJOR/bin:${PATH}"

CMD ["/bin/bash", "-c", "exec /sbin/init --log-color=true --log-level=info --log-target=console 3>&1"]
