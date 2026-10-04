# saphnet-homepage
The config files for Homepage for the Sapphic Homelab/Home Server

To deploy, use the image `ghcr.io/anarchobooleanism/saphnet-homepage:latest`

For debugging and development, be sure to run the command: `docker run -p 3000:3000 --env-file homepage.env -v ./config:/app/config -v ./icons:/app/public/icons -v ./images:/app/public/images ghcr.io/gethomepage/homepage`

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