FROM --platform=$BUILDPLATFORM erlang:22 as build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils \
    curl apt-transport-https ca-certificates git \
    locales sudo patch make wget cmake g++ build-essential libpam0g-dev 

ARG RIAK_VERSION

COPY files/install-riak.sh files/vars.config files/rebar.config.patch files/rebar.lock.patch files/riak.schema.patch /
RUN /install-riak.sh

# Install custom hooks
COPY files/prestart.d /tmp/portage-root/etc/riak/prestart.d
COPY files/poststart.d /tmp/portage-root/etc/riak/poststart.d

# Install custom start script
COPY files/riak-cluster.sh /tmp/portage-root/riak-cluster.sh

#####################################################################
# Riak image
FROM erlang:22-slim

# Prepare directrories
# Create riak user/group
RUN adduser --uid 102 --gecos riak --disabled-password --home /var/lib/riak riak && \
    mkdir -p /var/log/riak && \
    chown -R 102:102 /var/log/riak 

# Copy riak sources
COPY --chown=102:102 --from=build /tmp/portage-root/ /
COPY --from=build /opt/riak/_build/deb/rel/riak/lib /usr/lib/riak/lib
COPY --from=build /opt/riak/_build/deb/rel/riak/share /usr/lib/riak/share
COPY --from=build /opt/riak/_build/deb/rel/riak/releases /usr/lib/riak/releases
COPY --from=build /opt/riak/_build/deb/rel/riak/erts-10.7.2.18 /usr/lib/riak/erts-10.7.2.18
COPY --from=build /opt/riak/_build/deb/rel/riak/bin /usr/lib/riak/bin
COPY --chown=102:102 --from=build /opt/riak/_build/deb/rel/riak/etc/* /etc/riak/
COPY --chown=102:102 --from=build /opt/riak/_build/deb/rel/riak/data/* /var/lib/riak/data/
COPY --from=build /opt/riak/_build/deb/rel/riak/usr/bin/* /usr/sbin/

# Expose default ports
EXPOSE 8087 8098

RUN echo "riak  hard    nofile  1000000\n" >> /etc/security/limits.conf && \
    echo "riak  soft    nofile  65536" >> /etc/security/limits.conf
# Expose volumes for data and logs
VOLUME /var/log/riak
VOLUME /var/lib/riak

ENV RIAK_HOME /usr/lib/riak

WORKDIR /var/lib/riak
RUN chmod a+x /riak-cluster.sh

CMD ["/riak-cluster.sh"]
