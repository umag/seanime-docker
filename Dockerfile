# syntax=docker/dockerfile:1.4

# Stage 1: Node.js Builder
FROM --platform=$BUILDPLATFORM node:latest AS node-builder

# Set build args for cross-platform compatibility
ARG TARGETOS
ARG TARGETARCH

WORKDIR /tmp/build

# Copy only package files first for better caching
COPY ./seanime-web/package*.json ./

# Install dependencies with cache mount
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Copy source code after dependencies are installed
COPY ./seanime-web ./

RUN npm run build

# Stage 2: Go Builder
FROM --platform=$BUILDPLATFORM golang:latest AS go-builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /tmp/build

# Copy only go.mod and go.sum first for better caching
COPY go.mod go.sum ./

# Download Go modules with cache
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Copy source code after dependencies are downloaded
COPY . ./
COPY --from=node-builder /tmp/build/out /tmp/build/web

# Handle armv7 (32-bit ARM) builds specifically
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ]; then \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=7 go build -o seanime -trimpath -ldflags="-s -w"; \
    else \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o seanime -trimpath -ldflags="-s -w"; \
    fi

# Stage 3: Common Base
FROM --platform=$TARGETPLATFORM alpine:latest AS common-base

# Install common dependencies
RUN apk add --no-cache ca-certificates tzdata curl

# Stage 4: Default (Root) Variant
FROM common-base AS base

# Install standard ffmpeg
RUN apk add --no-cache ffmpeg

# Copy binary
COPY --from=go-builder /tmp/build/seanime /app/

WORKDIR /app
EXPOSE 43211

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:43211 || exit 1

CMD ["/app/seanime"]

# Stage 5: Rootless Variant
FROM common-base AS rootless

# Create user
RUN addgroup -S seanime -g 1000 && \
    adduser -S seanime -G seanime -u 1000 -s /sbin/nologin

# Install standard ffmpeg
RUN apk add --no-cache ffmpeg

# Copy binary with ownership
COPY --from=go-builder --chown=1000:1000 /tmp/build/seanime /app/

USER 1000
WORKDIR /app
EXPOSE 43211

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:43211 || exit 1

CMD ["/app/seanime"]

# Stage 6: Hardware Acceleration Variant
FROM common-base AS hwaccel
ARG TARGETARCH

# Create user and add to group
RUN addgroup -S seanime -g 1000 && \
    adduser -S seanime -G seanime -u 1000

# Install Jellyfin FFmpeg and Intel drivers (amd64 only)
RUN sed -i -e 's/^#\s*\(.*\/\)community/\1community/' /etc/apk/repositories && \
    apk update && \
    PACKAGES="jellyfin-ffmpeg mesa-va-gallium opencl-icd-loader" && \
    if [ "$TARGETARCH" = "amd64" ]; then \
    PACKAGES="$PACKAGES intel-media-driver libva-intel-driver"; \
    fi && \
    apk add --no-cache --repository=https://repo.jellyfin.org/releases/alpine/ $PACKAGES && \
    chmod +x /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/lib/jellyfin-ffmpeg/ffprobe && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe

# Copy binary with ownership
COPY --from=go-builder --chown=1000:1000 /tmp/build/seanime /app/

USER 1000
WORKDIR /app
EXPOSE 43211

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:43211 || exit 1

CMD ["/app/seanime"]
