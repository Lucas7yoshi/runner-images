# syntax=docker/dockerfile:1
# Gitea act_runner job image: .NET 11 + .NET 10 SDKs, Node.js LTS, common CLI tools.
FROM mcr.microsoft.com/dotnet/sdk:11.0-resolute

ARG DOTNET_EXTRA_CHANNELS="10.0"

LABEL org.opencontainers.image.source="https://github.com/Lucas7yoshi/runner-images" \
      org.opencontainers.image.description="act_runner job image with .NET 11 + 10 SDKs and Node.js LTS" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DOTNET_ROOT=/usr/share/dotnet

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base tools
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq openssh-client unzip zip xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Extra .NET SDK channels, side by side in the image's dotnet root
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
 && for ch in ${DOTNET_EXTRA_CHANNELS}; do \
      bash /tmp/dotnet-install.sh --channel "$ch" --install-dir "$DOTNET_ROOT" --no-path; \
    done \
 && rm /tmp/dotnet-install.sh \
 && dotnet --list-sdks

# Node.js LTS (official tarball; newest LTS release at build time)
RUN arch="$(dpkg --print-architecture)"; \
    case "$arch" in amd64) narch=x64;; arm64) narch=arm64;; *) echo "unsupported arch $arch"; exit 1;; esac; \
    ver="$(curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version')"; \
    echo "Installing Node.js $ver"; \
    curl -fsSL "https://nodejs.org/dist/${ver}/node-${ver}-linux-${narch}.tar.xz" -o /tmp/node.tar.xz; \
    curl -fsSL "https://nodejs.org/dist/${ver}/SHASUMS256.txt" | grep " node-${ver}-linux-${narch}.tar.xz\$" | sed "s|node-.*|/tmp/node.tar.xz|" | sha256sum -c -; \
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
      --exclude='*/CHANGELOG.md' --exclude='*/README.md' --exclude='*/LICENSE'; \
    rm /tmp/node.tar.xz; \
    node --version; npm --version
