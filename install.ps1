# Install Terminal Browser (tb.bat) for Windows
$RepoUrl = "https://raw.githubusercontent.com/falcga/tb/main/tb.bat"
$InstallDir = "$env:USERPROFILE\bin"
$TargetPath = "$InstallDir\tb.bat"

Write-Host "📦 Installing Terminal Browser (tb)..." -ForegroundColor Cyan

# Create folder if missing
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Host "✅ Created folder $InstallDir" -ForegroundColor Green
}

# Download script
Write-Host "⬇️  Downloading tb.bat..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $RepoUrl -OutFile $TargetPath

Write-Host "✅ Installed to $TargetPath" -ForegroundColor Green

# Add to PATH if needed
$envPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($envPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$envPath;$InstallDir", "User")
    Write-Host "🔄 Added $InstallDir to user PATH (restart your terminal)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "⚠️  Don't forget to set the JINA_TOKEN environment variable:" -ForegroundColor Yellow
Write-Host "   [Environment]::SetEnvironmentVariable('JINA_TOKEN', 'your_token_here', 'User')"
Write-Host ""
Write-Host "Now you can use: tb.bat https://example.com"
