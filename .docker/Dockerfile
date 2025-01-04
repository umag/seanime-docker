# Stage 1: Node.js Builder
FROM node:latest AS node-builder

COPY ./seanime-web /tmp/build

WORKDIR /tmp/build

RUN npm ci
RUN npm run build

# Stage 2: Go Builder
FROM golang:latest AS go-builder

COPY . /tmp/build
COPY --from=node-builder /tmp/build/out /tmp/build/web

WORKDIR /tmp/build

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o seanime -trimpath -ldflags="-s -w"

# Stage 3: Final Stage
FROM alpine:latest

# Install necessary packages ffmpeg
RUN apk add --no-cache \
    ffmpeg

# Copy the Go-built application from the previous stage
COPY --from=go-builder /tmp/build/seanime/seanime /app/seanime

# Work in /app directory
WORKDIR /app

# Expose ports: 8080 for Seanime, 8081 for qBittorrent Web UI
EXPOSE 43211

CMD ["/app/seanime"]