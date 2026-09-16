FROM ghcr.io/gethomepage/homepage:v2.3.0@sha256:f820276654539cdc2cf0169f28188d135919a7984fad76d83d8d5ff1383f3705
COPY config /app/config
COPY icons /app/public/icons
COPY images /app/public/images
