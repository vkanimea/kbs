FROM alpine:latest

LABEL maintainer="KBS Contributors"
LABEL version="0.115"
LABEL description="Knowledge Base System V0.115 — The governed, evolving knowledge graph"

# Install dependencies
RUN apk add --no-cache \
    bash \
    python3 \
    py3-pip \
    curl \
    git \
    && rm -rf /var/cache/apk/*

# Set working directory
WORKDIR /kbs-install

# Copy installer, templates, scripts, examples, and changelog
COPY install.sh .
COPY CHANGELOG.md .
COPY templates/ ./templates/
COPY scripts/ ./scripts/
COPY examples/ ./examples/

# Make scripts executable
RUN chmod +x install.sh scripts/*.sh scripts/*.py 2>/dev/null || true

# Run installer with container-appropriate path
ENV KBS_PATH=/root/kbs
ENV KB_NAME=main
ENV AUTO_INGEST=false

RUN ./install.sh

# Set working directory to KBS root
WORKDIR /root/kbs

# Expose port for chat API adapter webhook
EXPOSE 8080

# Persistent volumes for knowledge data
VOLUME ["/root/kbs/kb/main/wiki", "/root/kbs/kb/main/raw", "/root/kbs/kb/main/outputs"]

# Default command: show status
CMD ["/bin/bash", "-c", "/root/kbs/scripts/status.sh && echo '' && echo 'KBS V0.115 Ready.' && echo 'Run: Follow llm.md. Close session for main' && /bin/bash"]
