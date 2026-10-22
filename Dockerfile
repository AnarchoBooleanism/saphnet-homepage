## Python venv build stage
FROM debian:13.7-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f AS venv-builder

COPY --from=ghcr.io/astral-sh/uv:0.13.3@sha256:bee0a2a458fd956c5df7b8b4c5fed2257b0af34866e3da7b51db0be3acb375d1 /uv /uvx /bin/

WORKDIR /setup
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PROJECT_ENVIRONMENT="/opt/venv"
ENV UV_PYTHON_INSTALL_DIR="/opt/python"
ENV PATH="$UV_PROJECT_ENVIRONMENT/bin:/opt/python/bin:$PATH"

COPY api-server/pyproject.toml api-server/uv.lock api-server/.python-version ./
RUN mkdir -p /opt/venv /opt/python && \
    uv sync --frozen --no-install-project

## s6-overlay build stage
FROM debian:13.7-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f AS s6-builder
# renovate: datasource=github-releases depName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.2.3.2
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates xz-utils wget && \
    rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
        "amd64")    S6_ARCH="x86_64" ;; \
        "arm64")    S6_ARCH="aarch64" ;; \
        "riscv64")  S6_ARCH="riscv64" ;; \
        *) printf '"%s" is not a valid architecture!\n' "${TARGETARCH}" >&2 && exit 1;; \
    esac \
    && echo "Downloading s6-overlay for ${S6_ARCH}..." \
    && cd /tmp \
    && wget -O s6-overlay-noarch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
    && wget -O s6-overlay-noarch.tar.xz.sha256 "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz.sha256" \
    && wget -O s6-overlay-${S6_ARCH}.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" \
    && wget -O s6-overlay-${S6_ARCH}.tar.xz.sha256 "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz.sha256" \
    && sha256sum -c *.sha256 \
    && mkdir -p s6-root \
    && tar -C s6-root -Jxpf s6-overlay-noarch.tar.xz \
    && tar -C s6-root -Jxpf s6-overlay-${S6_ARCH}.tar.xz \
    && rm -rf s6-overlay-*.tar.xz s6-overlay-*.tar.xz.sha256

## Main build stage
FROM debian:13.7-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f
ARG NODE_VERSION=22

WORKDIR /app

# Set up base environment
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget gnupg \
    && mkdir -p /etc/apt/keyrings \
    && wget -qO- https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=venv-builder /opt/python /opt/python
COPY --from=venv-builder /bin/uv /bin/uvx /bin/
COPY --from=venv-builder /opt/venv /opt/venv
COPY --from=s6-builder /tmp/s6-root /
ENV PATH="/opt/venv/bin:/opt/python/bin:$PATH"

# Use the build from the official image, since all the NEXT_PUBLIC_ variables are handled there
COPY --from=ghcr.io/gethomepage/homepage:v2.6.0@sha256:3e38fe788223cb46a3ce1f046ef11667b40f7707fdca0dcbfa3f86c5c42bf1e8 --chown=1000:1000 /app /app

# Finally, copy project files
COPY homepage /app
COPY api-server /opt/api-server
COPY s6-overlay /etc/s6-overlay
RUN chmod +x /etc/s6-overlay/scripts/*

# The init-user service assumes this exists
RUN mkdir -p /app/config

USER root
ENV PUID=1000
ENV PGID=1000

# Create appuser
RUN groupadd -g 1000 appuser
RUN useradd -u 1000 -g appuser -M -s /bin/false appuser

ENV NODE_ENV=production
ENV HOSTNAME=::
ENV PORT=3000
EXPOSE $PORT

# We want the services to be able to access any environment variables, since they are
# similarly trusted, and the list of environment variables can change often
ENV S6_KEEP_ENV=1

HEALTHCHECK --interval=10s --timeout=3s --start-period=20s \
    CMD wget --no-verbose --tries=1 --spider -Y off http://127.0.0.1:$PORT/api/healthcheck || exit 1

ENTRYPOINT ["/init"]