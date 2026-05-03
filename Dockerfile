# Multi-stage Dockerfile for asika/asikad
# Build stage
FROM golang:1.25.0-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

# Download Go modules first (better layer caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build asika CLI
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w -X 'asika/common/version.Version=${VERSION}'" -o /asika ./cmd/asika

# Build asikad daemon
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w -X 'asika/common/version.Version=${VERSION}'" -o /asikad ./cmd/asikad

# Runtime stage
FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata

# Create asika user
RUN addgroup -S asika && adduser -S asika -G asika

WORKDIR /var/lib/asika

# Copy binaries from builder
COPY --from=builder /asika /usr/local/bin/asika
COPY --from=builder /asikad /usr/local/bin/asikad

# Create necessary directories
RUN mkdir -p /var/lib/asika /var/log/asika && \
    chown -R asika:asika /var/lib/asika /var/log/asika

# Switch to asika user
USER asika

# Expose default port (adjust if needed)
EXPOSE 8080

# Run asikad by default
ENTRYPOINT ["/usr/local/bin/asikad"]

# Default arguments
CMD ["serve"]
