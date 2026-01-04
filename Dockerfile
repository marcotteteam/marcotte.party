FROM tootsuite/mastodon-streaming:v4.5 as streaming

FROM tootsuite/mastodon:v4.5

USER root

RUN mkdir -p /var/cache/apt/archives/partial && \
  apt-get clean && \
  apt-get update && \
  apt-get install -y --no-install-recommends tmux nodejs

# Releases: https://github.com/caddyserver/caddy/releases/
RUN wget "https://github.com/caddyserver/caddy/releases/download/v2.8.4/caddy_2.8.4_linux_amd64.deb" -O caddy.deb && \
  dpkg -i caddy.deb

USER mastodon

# Releases: https://github.com/DarthSim/overmind/releases
RUN wget "https://github.com/DarthSim/overmind/releases/download/v2.5.1/overmind-v2.5.1-linux-amd64.gz" -O overmind.gz && \
  gunzip overmind.gz && \
  chmod +x overmind

ADD Procfile Caddyfile /opt/mastodon/

COPY --from=streaming /opt/mastodon/node_modules/ /opt/mastodon/streaming/node_modules/

ENTRYPOINT []
CMD ["./overmind", "start"]
