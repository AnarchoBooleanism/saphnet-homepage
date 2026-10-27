from contextlib import asynccontextmanager
from typing import Self

from fastapi import FastAPI, Depends, HTTPException, status
from pydantic_settings import BaseSettings, SettingsConfigDict
import httpx
import humanize

class Settings(BaseSettings):
    borgwarehouse_api_base_url: str = "https://borg.nas1.int.saphnet.xyz"
    borgwarehouse_token: str = ""

    model_config = SettingsConfigDict(env_prefix='HOMEPAGE_VAR_', extra='forbid')

settings = Settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    async_client = httpx.AsyncClient(timeout=httpx.Timeout(10.0))
    app.state.http_client = async_client
    
    yield
    
    await async_client.aclose()

app = FastAPI(lifespan=lifespan)

class BorgWarehouseClient:
    def __init__(self, client: httpx.AsyncClient):
        self.client = client
        self.base_url = settings.borgwarehouse_api_base_url

    async def get_repositories(self) -> dict:
        return await self._get("/api/v1/repositories")

    async def get_version(self) -> dict:
        return await self._get("/api/v1/version")

    async def _get(self, path: str) -> dict:
        try:
            response = await self.client.get(
                self.base_url + path,
                headers={
                    "Authorization": f"Bearer {settings.borgwarehouse_token}"
                }
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as exc:
            raise HTTPException(
                status_code=exc.response.status_code,
                detail=f"BorgWarehouse API returned error: {exc.response.text}"
            ) from exc
        except httpx.RequestError as exc:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"BorgWarehouse service is currently unreachable"
            ) from exc

    @classmethod
    def create_client(cls) -> Self:
        return cls(app.state.http_client)

@app.get("/health")
async def get_health_check():
    return {"status": "healthy"}

@app.head("/health")
async def head_health_check():
    return None

@app.get("/borgwarehouse")
async def get_borgwarehouse(
    client: BorgWarehouseClient = Depends(BorgWarehouseClient.create_client)
):
    repo_data = await client.get_repositories()
    version_data = await client.get_version()

    repo_list = repo_data.get("repoList", [])
    total_storage_used = sum(repo["storageUsed"] * 1e3 for repo in repo_list)

    return {
        "version": version_data.get("version"),
        "repoCount": len(repo_list),
        "storageUsed": total_storage_used
    }
    
def format_repository(repo: dict) -> dict:
    status_icon = "🟢" if repo.get("status") else "🔴"
    used_bytes = repo["storageUsed"] * 1e3
    total_bytes = repo["storageSize"] * 1e9
    usage_percent = (used_bytes / total_bytes) if total_bytes else 0.0

    return {
        "alias": f"{status_icon} {repo['alias']}",
        "status": f"{humanize.naturalsize(used_bytes)} / {humanize.naturalsize(total_bytes)} ({usage_percent:.0%})",
    }

@app.get("/borgwarehouse/repositories")
async def get_borgwarehouse_repositories(
    client: BorgWarehouseClient = Depends(BorgWarehouseClient.create_client)
):
    repo_data = await client.get_repositories()

    repo_data = {
        "repositories": [
            format_repository(repo) for repo in repo_data.get("repoList", [])
        ]
    }
    
    return repo_data