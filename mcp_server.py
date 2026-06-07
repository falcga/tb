#!/usr/bin/env python3
"""
MCP Server for Terminal Browser (tb) - Jina AI Reader API wrapper.

This server provides a local MCP-compatible interface for AI agents to:
- Fetch web page content via Jina Reader API (r.jina.ai)
- Search the web via Jina Search API (s.jina.ai)

The server runs locally on the user's machine and uses their JINA_API_KEY
from environment variables or a .env file. No credentials are hardcoded.
"""

import os
import json
import asyncio
import logging
import sys
from typing import Any, Dict, List, Optional
from dataclasses import dataclass
from pathlib import Path

import httpx
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    Tool,
    TextContent,
    CallToolResult,
)

# Load .env file if present
def load_env_file():
    """Load environment variables from .env file if it exists."""
    env_path = Path.cwd() / ".env"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, value = line.split("=", 1)
                    os.environ.setdefault(key.strip(), value.strip())

load_env_file()

# Configuration
JINA_API_KEY = os.environ.get("JINA_API_KEY") or os.environ.get("JINA_TOKEN")
JINA_CONTEXT_TOKEN = os.environ.get("JINA_CONTEXT_TOKEN")

# Setup logging (without sensitive data)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("tb-mcp-server")

@dataclass
class JinaResponse:
    """Structured response from Jina API."""
    success: bool
    content: str
    error: Optional[str] = None
    url: Optional[str] = None

class JinaClient:
    """Client for interacting with Jina AI Reader/Search APIs."""
    
    BASE_READ_URL = "https://r.jina.ai/"
    BASE_SEARCH_URL = "https://s.jina.ai/"
    
    def __init__(self, api_key: Optional[str] = None, context_token: Optional[str] = None):
        self.api_key = api_key
        self.context_token = context_token
        self.client = httpx.AsyncClient(timeout=30.0)
    
    def _build_headers(self) -> Dict[str, str]:
        """Build request headers. Never logs the API key."""
        headers = {"X-Engine": "browser"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        if self.context_token:
            headers["X-Context"] = self.context_token
        return headers
    
    async def fetch_page(self, url: str) -> JinaResponse:
        """Fetch a web page via Jina Reader API."""
        target_url = f"{self.BASE_READ_URL}{url}"
        logger.info(f"Fetching page: {target_url}")
        
        try:
            response = await self.client.get(
                target_url,
                headers=self._build_headers()
            )
            response.raise_for_status()
            return JinaResponse(
                success=True,
                content=response.text,
                url=target_url
            )
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error fetching {target_url}: {e.response.status_code}")
            return JinaResponse(
                success=False,
                content="",
                error=f"HTTP {e.response.status_code}: {e.response.text[:200]}",
                url=target_url
            )
        except httpx.RequestError as e:
            logger.error(f"Request error fetching {target_url}: {e}")
            return JinaResponse(
                success=False,
                content="",
                error=f"Request failed: {str(e)}",
                url=target_url
            )
    
    async def search(self, query: str) -> JinaResponse:
        """Search the web via Jina Search API."""
        from urllib.parse import quote
        encoded_query = quote(query)
        target_url = f"{self.BASE_SEARCH_URL}{encoded_query}"
        logger.info(f"Searching: {target_url}")
        
        try:
            response = await self.client.get(
                target_url,
                headers=self._build_headers()
            )
            response.raise_for_status()
            return JinaResponse(
                success=True,
                content=response.text,
                url=target_url
            )
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error searching {target_url}: {e.response.status_code}")
            return JinaResponse(
                success=False,
                content="",
                error=f"HTTP {e.response.status_code}: {e.response.text[:200]}",
                url=target_url
            )
        except httpx.RequestError as e:
            logger.error(f"Request error searching {target_url}: {e}")
            return JinaResponse(
                success=False,
                content="",
                error=f"Request failed: {str(e)}",
                url=target_url
            )
    
    async def close(self):
        """Close the HTTP client."""
        await self.client.aclose()

# Initialize server and client
server = Server("tb-mcp-server")
jina_client = JinaClient(api_key=JINA_API_KEY, context_token=JINA_CONTEXT_TOKEN)

@server.list_tools()
async def list_tools() -> List[Tool]:
    """List available tools."""
    return [
        Tool(
            name="fetch_page",
            description="Fetch a web page and return its text content via Jina Reader API",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "The URL to fetch (must start with http:// or https://)"
                    }
                },
                "required": ["url"]
            }
        ),
        Tool(
            name="search_web",
            description="Search the web and return results via Jina Search API",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query"
                    }
                },
                "required": ["query"]
            }
        ),
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Dict[str, Any]) -> CallToolResult:
    """Handle tool calls."""
    if name == "fetch_page":
        url = arguments.get("url")
        if not url:
            return CallToolResult(
                content=[TextContent(type="text", text="Error: Missing required parameter 'url'")],
                isError=True
            )
        if not url.startswith(("http://", "https://")):
            return CallToolResult(
                content=[TextContent(type="text", text="Error: URL must start with http:// or https://")],
                isError=True
            )
        
        result = await jina_client.fetch_page(url)
        if result.success:
            return CallToolResult(
                content=[TextContent(type="text", text=result.content)]
            )
        else:
            return CallToolResult(
                content=[TextContent(type="text", text=f"Error fetching {url}: {result.error}")],
                isError=True
            )
    
    elif name == "search_web":
        query = arguments.get("query")
        if not query:
            return CallToolResult(
                content=[TextContent(type="text", text="Error: Missing required parameter 'query'")],
                isError=True
            )
        
        result = await jina_client.search(query)
        if result.success:
            return CallToolResult(
                content=[TextContent(type="text", text=result.content)]
            )
        else:
            return CallToolResult(
                content=[TextContent(type="text", text=f"Error searching for '{query}': {result.error}")],
                isError=True
            )
    
    else:
        return CallToolResult(
            content=[TextContent(type="text", text=f"Error: Unknown tool '{name}'")],
            isError=True
        )

async def main():
    """Run the MCP server."""
    # Validate configuration - anonymous usage not supported
    if not JINA_API_KEY:
        logger.error("JINA_API_KEY or JINA_TOKEN environment variable is required.")
        logger.error("Get a free token from https://jina.ai/reader")
        logger.error("Set JINA_API_KEY in environment or .env file.")
        sys.exit(1)
    
    logger.info("Starting tb MCP server...")
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())