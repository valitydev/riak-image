FROM erlang:22 as build

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get update && apt-get -y install tzdata

ENV DEBIAN_FRONTEND teletype \
    TERM=xterm \
    LANG en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils && \
    apt-get -y --no-install-recommends dist-upgrade && \
    apt-get install -y --no-install-recommends curl apt-transport-https ca-certificates git && \
    apt-get install -y --no-install-recommends openjdk-11-jdk-headless locales logrotate sudo && \
    apt-get install -y patch make wget cmake g++ build-essential libpam0g-dev 

ARG RIAK_VERSION
COPY files/install-riak.sh /
COPY files/vars.config /
RUN /install-riak.sh

# Install custom hooks
COPY files/prestart.d /tmp/portage-root/etc/riak/prestart.d
COPY files/poststart.d /tmp/portage-root/etc/riak/poststart.d

# Install custom start script
COPY files/riak-cluster.sh /tmp/portage-root/riak-cluster.sh
#####################################################################
# Riak image
FROM erlang:22-slim
COPY --from=build /tmp/portage-root/ /

# Prepare directrories
RUN mkdir -p /etc/riak/prestart.d /etc/riak/poststart.d \
    /usr/lib/riak/ /var/lib/riak /var/log/riak /var/run/riak
#
# Copy riak sources
COPY --from=build /opt/riak/_build/deb/rel/riak/lib /usr/lib/riak/lib
COPY --from=build /opt/riak/_build/deb/rel/riak/share /usr/lib/riak/share
COPY --from=build /opt/riak/_build/deb/rel/riak/releases /usr/lib/riak/releases
COPY --from=build /opt/riak/_build/deb/rel/riak/erts-10.7.2.18 /usr/lib/riak/erts-10.7.2.18
COPY --from=build /opt/riak/_build/deb/rel/riak/bin /usr/lib/riak/bin
COPY --from=build /opt/riak/_build/deb/rel/riak/etc/* /etc/riak/
COPY --from=build /opt/riak/_build/deb/rel/riak/data/* /var/lib/riak/data/
COPY --from=build /opt/riak/_build/deb/rel/riak/usr/bin/* /usr/sbin/
#
#RUN busybox --install

# Expose default ports
EXPOSE 8087 8098

# Create riak user/group
RUN adduser --disabled-login --home /var/lib/riak riak; \
    chown -R riak:riak /var/lib/riak /var/log/riak /var/run/riak /etc/riak
RUN echo "riak  hard    nofile  1000000\n" >> /etc/security/limits.conf && \
    echo "riak  soft    nofile  65536" >> /etc/security/limits.conf

# Expose volumes for data and logs
VOLUME /var/log/riak
VOLUME /var/lib/riak

ENV RIAK_HOME /usr/lib/riak

WORKDIR /var/lib/riak
RUN chmod a+x /riak-cluster.sh
CMD ["/riak-cluster.sh"]
