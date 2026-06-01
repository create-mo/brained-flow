# publish-to-github.ps1
param(
    [string]$Token,
    [string]$RepoName = "brained-flow",
    [string]$Description = "Personal knowledge-driven workflow system for Claude",
    [switch]$Private
)

if (-not $Token) {
    $Token = Read-Host "GitHub Personal Access Token (github.com/settings/tokens/new, scope: repo)"
}

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# 1. Init git if needed
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

# 2. Set identity
git config user.email "salakhetdinovmu@gmail.com"
git config user.name "Mahmud Salakhetdinov"

# 3. Stage and commit
git add .
$st = git status --porcelain
if ($st) {
    git commit -m "Initial commit"
} else {
    Write-Host "Nothing to commit."
}

# 4. Create GitHub repo via API
$headers = @{
    Authorization = "Bearer $Token"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$body = @{
    name = $RepoName
    description = $Description
    private = $Private.IsPresent
    auto_init = $false
} | ConvertTo-Json

Write-Host "Creating GitHub repository '$RepoName'..."
$repoUrl = $null
try {
    $resp = Invoke-RestMethod -Method Post -Uri "https://api.github.com/user/repos" -Headers $headers -Body $body -ContentType "application/json"
    $repoUrl = $resp.clone_url
    Write-Host "Repo created: $($resp.html_url)"
} catch {
    $code = $_.Exception.Response.StatusCode
    if ($code -eq 422) {
        $me = (Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers).login
        $repoUrl = "https://github.com/$me/$RepoName.git"
        Write-Host "Repo already exists, using $repoUrl"
    } else {
        throw
    }
}

# 5. Push with token auth
$authUrl = $repoUrl -replace "https://", "https://$Token@"
git remote remove origin 2>$null
git remote add origin $authUrl
git push -u origin main

# Remove token from remote
git remote set-url origin $repoUrl

Write-Host ""
Write-Host "Done! https://github.com/create-mo/$RepoName"
