FROM alpine:latest

LABEL maintainer="KBS Contributors"
LABEL version="0.115"
LABEL description="Knowledge Base System — the governed, evolving knowledge graph"

# Install dependencies (tini = PID 1 signal handling)
RUN apk add --no-cache \
    bash \
    python3 \
    py3-pip \
    curl \
    git \
    tini \
    && rm -rf /var/cache/apk/*

# ─── Build the SYSTEM payload (not the instance) ─────────────────────────────
# The instance lives in a bind-mounted directory (see docker-compose.yml); this
# image only carries the system, which the entrypoint seeds/refreshes.
WORKDIR /kbs-build

COPY install.sh .
COPY CHANGELOG.md .
COPY VERSION .
COPY templates/ ./templates/
COPY scripts/ ./scripts/
COPY examples/ ./examples/

RUN chmod +x install.sh scripts/*.sh scripts/*.py 2>/dev/null || true

ENV KBS_PATH=/opt/kbs-system
ENV KB_NAME=main
ENV AUTO_INGEST=false

RUN ./install.sh

COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# ─── Runtime: instance directory (bind-mount target) ─────────────────────────
ENV KBS_PATH=/root/kbs
WORKDIR /root/kbs

# Expose port for chat API adapter webhook
EXPOSE 8080

# Persistent knowledge data — bind-mount a host directory here (private repo)
VOLUME ["/root/kbs"]

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash", "-c", "/root/kbs/scripts/status.sh && echo '' && echo 'KBS ready.' && echo 'Run: Follow agents.md. Close session for main' && /bin/bash"]
