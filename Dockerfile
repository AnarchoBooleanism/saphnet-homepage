FROM ghcr.io/gethomepage/homepage:v2.4.0@sha256:643bd0be730d40f69d58028a55d1a896739333e8815786df42bc97f109ecbe61
COPY config /app/config
COPY icons /app/public/icons
COPY images /app/public/images
