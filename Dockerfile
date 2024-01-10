FROM ubuntu:22.04

LABEL shardman_build=14.10.1
ARG PG_MAJOR=14
ARG PGHOME=/var/lib/pgpro
ARG LC_ALL=C.UTF-8
ARG LANG=C.UTF-8
ARG CLUSTER_NAME=cluster0

ENV PG_MAJOR=${PG_MAJOR}
ENV CLUSTER_NAME=${CLUSTER_NAME} 
ENV PGDATA="/var/lib/pgpro/sdm-${PG_MAJOR}/data" 
ENV PATH="/opt/pgpro/sdm-${PG_MAJOR}/bin:${PATH}" 
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux \
    && ulimit -s unlimited \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gnupg curl wget ca-certificates \
    && printf "deb [arch=amd64] https://repo.postgrespro.ru/pgprosm-14/ubuntu jammy main" > /etc/apt/sources.list.d/shardman.list \
    && curl -fsSL https://repo.postgrespro.ru/pgprosm-14/keys/GPG-KEY-POSTGRESPRO | gpg --dearmor | tee /etc/apt/trusted.gpg.d/shardman.gpg > /dev/null \
    && apt update -y \
    && apt-get install -y --no-install-recommends \
        systemd-sysv systemd libicu70 libev4 \
        libpam0g libssl3 libxml2 tzdata \
        ssl-cert locales dbus-x11 libipc-run-perl \
        libreadline8 pkg-config zlib1g \
        openssh-client openssh-server \
        postgrespro-sdm-${PG_MAJOR}-server \
        postgrespro-sdm-${PG_MAJOR}-client \
        postgrespro-sdm-${PG_MAJOR}-contrib \
        postgrespro-sdm-${PG_MAJOR}-libs \
        pg-probackup-sdm-${PG_MAJOR} \
        shardman-services \
        shardman-tools \
    && mkdir -p /var/lib/pgpro/sdm-${PG_MAJOR}/data /etc/shardman /var/lib/postgresql/.ssh \
    && printf "StrictHostKeyChecking no\n" >> /etc/ssh/ssh_config.d/pg.conf \
    && printf "UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config.d/pg.conf \
    && ssh-keygen -t rsa -N '' -f  /var/lib/postgresql/.ssh/id_rsa \
    && cat /var/lib/postgresql/.ssh/id_rsa.pub > /var/lib/postgresql/.ssh/authorized_keys \
    && chown postgres:postgres -R /var/lib/postgresql /etc/shardman /opt/pgpro /var/lib/pgpro \
    && chmod 0600 /var/lib/postgresql/.ssh/id_rsa \
    && chmod 700 /var/lib/pgpro/sdm-${PG_MAJOR}/data \
    && locale-gen en_US.UTF-8 \
    && systemctl enable ssh shardmand@${CLUSTER_NAME} \
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

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init", "--log-color", "false", "--log-level", "info", "--log-target", "console"]
