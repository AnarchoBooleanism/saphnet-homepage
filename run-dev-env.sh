#!/bin/sh
# Container engine-agnostic script for creating a development environment. 

set -e

DISABLE_COMPOSE=${DISABLE_COMPOSE:-false}

export PUID=${PUID:-$(id -u)}
export PGID=${PGID:-$(id -g)}

export HOMEPAGE_PORT=${HOMEPAGE_PORT:-3000}
export API_PORT=${API_PORT:-3001}

# Note that this file should exist before running.
export ENV_FILE=${ENV_FILE:-'./homepage.env'}

if [ -z "${CONTAINER_ENGINE}" ]; then
    printf "A container engine has not been specified. Checking for a container engine.\n"

    if command -v docker >/dev/null 2>&1; then
        printf 'Docker is installed, setting that as the container engine...\n'
        CONTAINER_ENGINE=docker
    elif command -v podman >/dev/null 2>&1; then
        printf 'Podman is installed, setting that as the container engine...\n'
        CONTAINER_ENGINE=podman
    else
        printf "No supported container engines are installed, exiting...\n" >&2
        exit 1
    fi
else
    printf 'The container engine has been specified: %s. Checking whether it is installed.\n' "${CONTAINER_ENGINE}"
    if ! command -v "${CONTAINER_ENGINE}" >/dev/null 2>&1; then
        printf 'The specified container engine (%s) is NOT installed! Exiting...\n' "${CONTAINER_ENGINE}" >&2
        exit 1
    fi
fi

if "${CONTAINER_ENGINE}" compose version >/dev/null; then
    compose_installed=true
    printf 'Compose is installed for the %s container engine.\n' "${CONTAINER_ENGINE}"
else
    compose_installed=false
    printf 'Compose is NOT installed for the %s container engine.\n' "${CONTAINER_ENGINE}"
fi

if [ "$compose_installed" = "true" ] && [ ! "$DISABLE_COMPOSE" = "true" ]; then
    exec "${CONTAINER_ENGINE}" compose -f compose.dev.yaml up --build
else
    if [ "$DISABLE_COMPOSE" = "true" ]; then
        printf "Running without Compose, as the override variable has been set to true.\n"
    fi

    exec "${CONTAINER_ENGINE}" run --rm \
        --name homepage-dev \
        -p "${HOMEPAGE_PORT}:3000" \
        -p "${API_PORT}:3001" \
        -v ./homepage/config:/app/config \
        -v ./homepage/public/icons:/app/public/icons \
        -v ./homepage/public/images:/app/public/images \
        -v ./api-server/app:/opt/api-server/app \
        -e ENVIRONMENT="development" \
        -e PUID="${PUID}" \
        -e PGID="${PGID}" \
        --env-file "${ENV_FILE}" \
        $("${CONTAINER_ENGINE}" build -q .)
fi