from contextlib import asynccontextmanager

from fastapi import FastAPI
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

@app.get("/health")
async def get_health_check():
    return {"status": "healthy"}

@app.head("/health")
async def head_health_check():
    return None

@app.get("/borgwarehouse")
async def get_borgwarehouse():
    api_url = f"{settings.borgwarehouse_api_base_url}/api/v1/repositories"
    async with httpx.AsyncClient() as client:
        raw_response = await client.get(
            api_url,
            headers={
                "Authorization": f"Bearer {settings.borgwarehouse_token}"
            }
        )
        api_response = raw_response.json()
    
    api_url_2 = f"{settings.borgwarehouse_api_base_url}/api/v1/version"
    async with httpx.AsyncClient() as client:
        raw_response = await client.get(
            api_url_2,
            headers={
                "Authorization": f"Bearer {settings.borgwarehouse_token}"
            }
        )
        api_response_2 = raw_response.json()

    return {
        "version": api_response_2["version"],
        "repoCount": len(api_response["repoList"]),
        "storageUsed": sum(repo["storageUsed"] * 1e3 for repo in api_response["repoList"])
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
async def get_borgwarehouse_repositories():
    api_url = f"{settings.borgwarehouse_api_base_url}/api/v1/repositories"
    async with httpx.AsyncClient() as client:
        raw_response = await client.get(
            api_url,
            headers={
                "Authorization": f"Bearer {settings.borgwarehouse_token}"
            }
        )
        api_response = raw_response.json()

    repo_data = {
        "repositories": [
            format_repository(repo) for repo in api_response["repoList"]
        ]
    }
    
    return repo_data