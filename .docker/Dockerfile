# syntax=docker/dockerfile:1.4

# Stage 1: Node.js Builder
FROM --platform=$BUILDPLATFORM node:latest AS node-builder

# Set build args for cross-platform compatibility
ARG TARGETOS
ARG TARGETARCH

COPY ./seanime-web /tmp/build

WORKDIR /tmp/build

RUN npm install
RUN npm run build

# Stage 2: Go Builder
FROM --platform=$BUILDPLATFORM golang:latest AS go-builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

COPY . /tmp/build
COPY --from=node-builder /tmp/build/out /tmp/build/web

WORKDIR /tmp/build

# Handle armv7 (32-bit ARM) builds specifically
RUN if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ]; then \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=7 go build -o seanime -trimpath -ldflags="-s -w"; \
    else \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o seanime -trimpath -ldflags="-s -w"; \
    fi

# Stage 3: Final Stage
FROM --platform=$TARGETPLATFORM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
    ffmpeg ca-certificates

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
