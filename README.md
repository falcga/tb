# Terminal Browser (tb) – Super‑fast terminal web browser & MCP Server

**tb** lets you view web pages and perform searches directly from your terminal using the [Jina Reader API](https://jina.ai/reader).  
Works on **Linux**, **macOS**, **Windows** (CMD, PowerShell, WSL, Git Bash).

- 🚀 Instant text‑only version of any page  
- 🔍 Search using `s.jina.ai`  
- 🎨 Optional pager (`less` / `more`) with `--pager` flag  
- 🔐 Optional token authentication & context token  
- 📦 One‑command installation
- 🤖 **MCP Server** for AI agent integration (Claude Desktop, Cursor, etc.)

## Installation

### Linux / macOS / WSL / Git Bash

```bash
curl -sSL https://raw.githubusercontent.com/falcga/tb/main/install.sh | bash
```

Then restart your terminal or run `source ~/.bashrc` / `source ~/.zshrc`.

### Windows (PowerShell as Administrator)

```powershell
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/falcga/tb/main/install.ps1' -OutFile install.ps1; ./install.ps1"
```

Or manually: download `tb.bat` and place it in a folder that is in your `%PATH%`.

### MCP Server Installation (for AI agents)

```bash
# Clone the repository
git clone https://github.com/falcga/tb.git
cd tb

# Install Python dependencies
pip install -r requirements.txt

# Copy .env.example to .env and add your Jina API key
cp .env.example .env
# Edit .env and add your JINA_API_KEY
```

## Usage

### 1. Get an API token (Required)

**Anonymous usage is not supported.** You must obtain a free API token from [Jina AI Reader](https://jina.ai/reader) to use this tool.

### 2. First run — save your token (recommended)

On first use, provide your token via the `--token` flag. It will be saved securely to a config file (`~/.config/tb/config` on Linux/macOS, `%APPDATA%\tb\config` on Windows) so you don't need to pass it again:

```bash
# Linux/macOS/WSL/Git Bash
tb --token jina_your_token_here https://example.com
# ✓ Token saved to ~/.config/tb/config

# Windows CMD
tb.bat --token jina_your_token_here https://example.com
# ✓ Token saved to %APPDATA%\tb\config

# Windows PowerShell
tb.bat --token jina_your_token_here https://example.com
# ✓ Token saved to %APPDATA%\tb\config
```

After this, you can use `tb` without the `--token` flag:

```bash
tb https://example.com
tb "search query"
```

### 3. Alternative: Set environment variables

Instead of using `--token`, you can set the token via environment variables:

```bash
export JINA_API_KEY="jina_your_token_here"          # Linux/macOS (preferred)
export JINA_TOKEN="jina_your_token_here"            # Linux/macOS (legacy)
set JINA_API_KEY=jina_your_token_here               # Windows CMD
$env:JINA_API_KEY="jina_your_token_here"            # Windows PowerShell
```

For a context token (sent as `X-Context` header):

```bash
export JINA_CONTEXT_TOKEN="your_context"
```

### 4. Browse the web (CLI)

Open a webpage:

```bash
tb https://example.com
```

Search the web:

```bash
tb "how to install python"
```

### Options

| Flag | Description |
|------|-------------|
| `--token TOKEN` | Jina API token (overrides `JINA_API_KEY`/`JINA_TOKEN`) |
| `--context TOKEN` | Context token (sent as `X-Context` header) |
| `--raw` | Output raw text (default) |
| `--pager` | Output with pager (less/more) |
| `--help`, `-h` | Show help message |

### Examples

```bash
# Open a page (raw output by default)
tb https://example.com

# Open a page with pager
tb --pager https://example.com

# Open a page with a temporary token (overrides environment)
tb --token jina_xyz https://news.ycombinator.com

# Search with a context token
tb --context session_123 "bash best practices"

# Save output to a file (raw by default)
tb https://example.com > page.txt
```

## MCP Server Usage (for AI Agents)

The MCP server runs **locally on your machine** and uses your Jina API key from environment variables or a `.env` file. No credentials are shared or hardcoded.

### Running the MCP Server

```bash
# From the tb directory
python -m mcp_server
```

The server communicates via stdio (standard input/output) and is designed to be launched by an MCP-compatible client.

### Configuration for Claude Desktop

Add to your Claude Desktop configuration (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS, `%APPDATA%\Claude\claude_desktop_config.json` on Windows):

```json
{
  "mcpServers": {
    "tb": {
      "command": "python",
      "args": ["-m", "mcp_server"],
      "cwd": "/path/to/tb",
      "env": {
        "JINA_API_KEY": "your_jina_api_key_here",
        "JINA_CONTEXT_TOKEN": "optional_context_token"
      }
    }
  }
}
```

See `mcp_config_claude_desktop.json` for a template.

### Configuration for Cursor

Add to your Cursor MCP configuration (`.cursor/mcp.json` in your workspace):

```json
{
  "mcpServers": {
    "tb": {
      "command": "python",
      "args": ["-m", "mcp_server"],
      "cwd": "${workspaceFolder}",
      "env": {
        "JINA_API_KEY": "${env:JINA_API_KEY}",
        "JINA_CONTEXT_TOKEN": "${env:JINA_CONTEXT_TOKEN}"
      }
    }
  }
}
```

See `mcp_config_cursor.json` for a template.

### Available MCP Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `fetch_page` | Fetch a web page and return its text content via Jina Reader API | `url` (string, required) |
| `search_web` | Search the web and return results via Jina Search API | `query` (string, required) |

### Example Agent Usage

Once configured, AI agents can use the tools like:

```
User: "Fetch the content of https://example.com"
Agent: [calls fetch_page with url="https://example.com"]

User: "Search for 'python async best practices'"
Agent: [calls search_web with query="python async best practices"]
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `JINA_API_KEY` | API token for Jina Reader (preferred) | **Yes** |
| `JINA_TOKEN` | API token for Jina Reader (legacy, also supported) | **Yes** |
| `JINA_CONTEXT_TOKEN` | Context token (sent as `X-Context`) | No |

An API key (`JINA_API_KEY` or `JINA_TOKEN`) is required. Requests without a token will fail.

## Requirements

### CLI (tb.sh / tb.bat)
- **curl** (pre‑installed on most systems, required)
- **less** or **more** (for paging, optional – use `--raw` to bypass)
- No other dependencies

### MCP Server
- **Python 3.10+**
- **mcp** package (`pip install mcp`)
- **httpx** package (`pip install httpx`)

## Uninstallation

- **Linux/macOS**: `sudo rm /usr/local/bin/tb`
- **Windows**: Delete `tb.bat` from your `%USERPROFILE%\bin` (or wherever you placed it) and remove that folder from your `PATH` if desired.
- **MCP Server**: Remove the server configuration from your AI client config.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `curl: command not found` | Install curl (e.g., `apt install curl` / `brew install curl`) |
| `Error: Request failed` | Check your internet connection. If you provided a token, ensure it is valid. |
| No output or strange characters | Try `--raw` mode or check if the URL/search query is correct. |
| MCP server fails to start | Ensure Python 3.10+ is installed and run `pip install -r requirements.txt` |
| "JINA_API_KEY not set" warning | Set `JINA_API_KEY` in your environment or `.env` file for higher rate limits |

## License

MIT © 2025 falcga

## Acknowledgements

This tool is an **unofficial** third‑party client for the public Jina Reader API.  
It respects the API's intended usage:

- No web scraping or automated extraction from jina.ai
- No reverse engineering or creation of competing services
- API tokens are optional and passed exactly as documented (`Authorization: Bearer` header)
- The required `X-Engine: browser` header is always sent

For heavy or automated usage, please obtain your own free token from [Jina AI Reader](https://jina.ai/reader) and respect their rate limits.

See [Jina AI Terms](https://jina.ai/legal/terms) and [Privacy Policy](https://jina.ai/legal/privacy) for details.

## ⚠️ Important Limitations & Licensing Notes

### Jina AI Terms of Service
- This tool uses the **public Jina Reader API** which is subject to [Jina AI Terms of Service](https://jina.ai/legal/terms).
- **Free tier usage may be limited to non-commercial purposes only.** Review Jina's current terms before using in production or commercial contexts.
- Rate limits apply. Anonymous usage has stricter limits than authenticated requests.
- Do not create public proxies or services that bypass Jina's rate limits or terms.

### Security & Privacy
- **No hardcoded credentials**: API keys are read only from environment variables or `.env` files.
- **Local-only execution**: The MCP server runs on your machine. No data is sent to third parties except Jina AI.
- **No secret logging**: The server never logs API keys or tokens.
- **User-supplied keys**: Each user must provide their own Jina API key.

### MCP Server
- The MCP server is designed for **local, single-user use only**.
- Do not deploy as a public/shared service using your credentials.
- Each user/agent should run their own instance with their own API key.
</content>
