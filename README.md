# Terminal Browser (tb) – Super‑fast terminal web browser

**tb** lets you view web pages and perform searches directly from your terminal using the [Jina Reader API](https://jina.ai/reader).  
Works on **Linux**, **macOS**, **Windows** (CMD, PowerShell, WSL, Git Bash).

- 🚀 Instant text‑only version of any page  
- 🔍 Search using `s.jina.ai`  
- 🎨 Automatic pager (`less` / `more`)  
- 🔐 Optional token authentication & context token  
- 📦 One‑command installation  

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

## Usage

### 1. (Optional) Get an API token

You can use **tb without a token** – requests will be sent anonymously.  
For higher rate limits or special features, get a free token from [Jina AI Reader](https://jina.ai/reader).

### 2. Set environment variables (optional)

```bash
export JINA_TOKEN="jina_your_token_here"          # Linux/macOS
set JINA_TOKEN=jina_your_token_here               # Windows CMD
$env:JINA_TOKEN="jina_your_token_here"            # Windows PowerShell
```

For a context token (sent as `X-Context` header):

```bash
export JINA_CONTEXT_TOKEN="your_context"
```

### 3. Browse the web

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
| `--token TOKEN` | Jina API token (overrides `JINA_TOKEN`) |
| `--context TOKEN` | Context token (sent as `X-Context` header) |
| `--raw` | Output without pager (useful for piping to files) |
| `--help`, `-h` | Show help message |

### Examples

```bash
# Open a page with a temporary token (overrides environment)
tb --token jina_xyz https://news.ycombinator.com

# Search with a context token
tb --context session_123 "bash best practices"

# Save output to a file (no pager)
tb --raw https://example.com > page.txt

# Anonymous usage (no token)
tb "latest tech news"
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `JINA_TOKEN` | API token for Jina Reader | No |
| `JINA_CONTEXT_TOKEN` | Context token (sent as `X-Context`) | No |

If `JINA_TOKEN` is not set and no `--token` is provided, the `Authorization` header is omitted entirely.

## Requirements

- **curl** (pre‑installed on most systems, required)
- **less** or **more** (for paging, optional – use `--raw` to bypass)
- No other dependencies

## Uninstallation

- **Linux/macOS**: `sudo rm /usr/local/bin/tb`
- **Windows**: Delete `tb.bat` from your `%USERPROFILE%\bin` (or wherever you placed it) and remove that folder from your `PATH` if desired.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `curl: command not found` | Install curl (e.g., `apt install curl` / `brew install curl`) |
| `Error: Request failed` | Check your internet connection. If you provided a token, ensure it is valid. |
| No output or strange characters | Try `--raw` mode or check if the URL/search query is correct. |

## License

MIT © 2025 falcga

## Acknowledgements

This tool is an **unofficial** third‑party client for the public Jina Reader API.  
It respects the API’s intended usage:

- No web scraping or automated extraction from jina.ai
- No reverse engineering or creation of competing services
- API tokens are optional and passed exactly as documented (`Authorization: Bearer` header)
- The required `X-Engine: browser` header is always sent

For heavy or automated usage, please obtain your own free token from [Jina AI Reader](https://jina.ai/reader) and respect their rate limits.

See [Jina AI Terms](https://jina.ai/legal/terms) and [Privacy Policy](https://jina.ai/legal/privacy) for details.
