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

# Stage 3: QEMU for multi-platform builds
FROM --platform=$BUILDPLATFORM tonistiigi/binfmt:latest AS qemu

# Stage 4: Final Stage
FROM --platform=$TARGETPLATFORM alpine:3.22.2


# Install necessary packages
RUN apk add --no-cache \
    ffmpeg \
    ca-certificates

# Fix missing certificate (#1)
COPY Comodo_AAA_Services_root.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

# Copy the Go-built application from the previous stage
COPY --from=go-builder /tmp/build/seanime /app/

# Work in /app directory
WORKDIR /app

# Expose port 43211
EXPOSE 43211

# Command to run the application
CMD ["/app/seanime"]
