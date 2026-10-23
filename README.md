# saphnet-homepage
Custom image for Homepage, tailored to the Sapphic Homelab/Home Server

To deploy, use the image `ghcr.io/anarchobooleanism/saphnet-homepage:latest`

For debugging and development, be sure to run the command: `docker compose -f compose.dev.yaml up --build`

Alternatively, without Docker Compose, you can run the command:
```sh
docker run -d \
  --name homepage-dev \
  -p 3000:3000 \
  -p 3001:3001 \
  -v ./homepage/config:/app/config \
  -v ./homepage/public/icons:/app/public/icons \
  -v ./homepage/public/images:/app/public/images \
  -v ./api-server/app:/opt/api-server/app \
  -e ENVIRONMENT="development" \
  -e PUID="${PUID:-${UID:-1000}}" \
  -e PGID="${PUID:-${GID:-100}}" \
  --env-file ./homepage.env \
  $(docker build -q .)
```

Environment variables to pass secrets to in `homepage.env`:
- `HOMEPAGE_VAR_PROXMOX_USERNAME`
- `HOMEPAGE_VAR_PROXMOX_PASSWORD`
- `HOMEPAGE_VAR_PBS_USERNAME`
- `HOMEPAGE_VAR_PBS_PASSWORD`
- `HOMEPAGE_VAR_TRUENAS_API_KEY`
- `HOMEPAGE_VAR_KOMODO_API_KEY`
- `HOMEPAGE_VAR_KOMODO_SECRET`
- `HOMEPAGE_VAR_HA_API_KEY`
- `HOMEPAGE_VAR_FAH_USERNAME`
- `HOMEPAGE_VAR_JELLYFIN_API_KEY`
- `HOMEPAGE_VAR_SEERR_API_KEY`
- `HOMEPAGE_VAR_PROWLARR_API_KEY`
- `HOMEPAGE_VAR_RADARR_API_KEY`
- `HOMEPAGE_VAR_RADARR_ANIME_API_KEY`
- `HOMEPAGE_VAR_SONARR_API_KEY`
- `HOMEPAGE_VAR_SONARR_ANIME_API_KEY`
- `HOMEPAGE_VAR_DELUGE_PASSWORD`
- `HOMEPAGE_VAR_NPM_INT_USERNAME`
- `HOMEPAGE_VAR_NPM_INT_PASSWORD`
- `HOMEPAGE_VAR_PTERODACTYL_API_KEY`
- `HOMEPAGE_VAR_TRAEFIK_PASSWORD`
- `HOMEPAGE_VAR_UPTIME_KUMA_USERNAME`
- `HOMEPAGE_VAR_UPTIME_KUMA_PASSWORD`
- `HOMEPAGE_VAR_BORGWAREHOUSE_TOKEN`