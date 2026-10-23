#!/bin/sh
# Note that this script expects PUID and PGID to already be set, which should already be done in the Dockerfile

set -e

# $1 should be the path to a directory/file
chown_path() {
    if [ -e "$1" ]; then
        current_uid=$(stat -c %u /app/config)
        current_gid=$(stat -c %g /app/config)

        if [ "$current_uid" -ne "$PUID" ] || [ "$current_gid" -ne "$PGID" ]; then
            echo "Fixing ownership of ${1}..."
            if ! chown -R "$PUID:$PGID" "$1" 2>/dev/null; then
            echo "Warning: Could not chown "$1"; continuing anyway..."
            fi
        else
            echo "$1 already owned by correct UID/GID, skipping chown."
        fi
        else
        echo "$1 does not exist; skipping ownership check."
        fi
}

if [ "$PUID" = "0" ]; then
    printf "As we are running as root, skipping ownership changes...\n"
    exit 0
fi

appuser_current_uid=$(id -u appuser)
appuser_current_gid=$(getent group appuser | cut -d: -f3)

if [ ! "$appuser_current_gid" = "$PGID" ]; then
    printf 'Setting GID of group appuser to %s...\n' "$PGID"
    groupmod -o -g "$PGID" appuser
else
    printf 'Group appuser is already GID %s.\n' "$appuser_current_gid"
fi

if [ ! "$appuser_current_gid" = "$PGID" ]; then
    printf 'Setting UID of user appuser to %s...\n' "$PGID"
    usermod -o -u "$PUID" appuser
else
    printf 'User appuser is already UID %s.\n' "$appuser_current_uid"
fi

# Fix directory permissions
# Homepage
# See: https://github.com/gethomepage/homepage/blob/dev/docker-entrypoint.sh
chown_path /app/config
chown_path /app/config/logs
chown_path /app/.next
# API server
chown_path /opt/api-server/app