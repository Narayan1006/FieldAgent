# upload_release.ps1
# Run this script once to create a GitHub Release and upload the APK.
# Requires: GitHub Personal Access Token with 'repo' scope
#
# Usage:
#   .\upload_release.ps1 -Token "ghp_xxxxxxxxxxxxxxxxxxxx"

param(
    [Parameter(Mandatory=$true)]
    [string]$Token
)

$owner = "Narayan1006"
$repo  = "FieldAgent"
$tag   = "v1.0.0"
$apk   = "build\app\outputs\flutter-apk\app-release.apk"

$headers = @{
    "Authorization" = "Bearer $Token"
    "Accept"        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

Write-Host "🚀 Creating GitHub Release $tag..." -ForegroundColor Cyan

# Create the release
$releaseBody = @{
    tag_name         = $tag
    target_commitish = "master"
    name             = "FieldAgent v1.0.0 — 7 Patient Categories"
    body             = @"
## FieldAgent v1.0.0

**AI-powered offline-first mobile app for ASHA healthcare workers in rural India.**

### What's new
- 7 patient categories: Maternal, Child Immunization, TB, Malaria/Dengue, Family Planning, Newborn Care, General
- Offline-first SQLite + Firebase Firestore sync
- On-device Gemma 4 E4B AI referral notes
- Category filter tabs on home screen
- Type-specific visit forms and danger flags

### Install
1. Download `app-release.apk` below
2. Enable "Install from unknown sources" on your Android device
3. Install via ADB: ``adb install app-release.apk``
4. On first launch, connect to WiFi and download the Gemma 4 E4B model (~3.65 GB)
5. After that — works fully offline!

### Requirements
- Android 6.0+ (API 23+), arm64
- 5 GB free storage (for Gemma model)
- WiFi for first-time model download only
"@
    draft            = $false
    prerelease       = $false
} | ConvertTo-Json

$release = Invoke-RestMethod `
    -Uri "https://api.github.com/repos/$owner/$repo/releases" `
    -Method POST `
    -Headers $headers `
    -Body $releaseBody `
    -ContentType "application/json"

Write-Host "✅ Release created: $($release.html_url)" -ForegroundColor Green

# Upload the APK asset
Write-Host "📦 Uploading APK ($([Math]::Round((Get-Item $apk).Length / 1MB, 1)) MB)..." -ForegroundColor Cyan

$uploadUrl = $release.upload_url -replace '\{\?name,label\}', ''
$apkBytes  = [System.IO.File]::ReadAllBytes((Resolve-Path $apk))

Invoke-RestMethod `
    -Uri "${uploadUrl}?name=app-release.apk&label=FieldAgent-v1.0.0-arm64.apk" `
    -Method POST `
    -Headers $headers `
    -Body $apkBytes `
    -ContentType "application/vnd.android.package-archive" | Out-Null

Write-Host "✅ APK uploaded successfully!" -ForegroundColor Green
Write-Host "🔗 Download: https://github.com/$owner/$repo/releases/latest/download/app-release.apk" -ForegroundColor Yellow
