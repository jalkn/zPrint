[CmdletBinding(DefaultParameterSetName = "Help")]
param(
    [Parameter(ParameterSetName = "Initialize")]
    [switch]$Initialize,

    [Parameter(ParameterSetName = "Build")]
    [switch]$Build,

    [Parameter(ParameterSetName = "BuildBrand")]
    [switch]$BuildBrand,

    [Parameter(ParameterSetName = "BuildCatalog")]
    [switch]$BuildCatalog,

    [Parameter(ParameterSetName = "BuildCore")]
    [switch]$BuildCore,

    [Parameter(ParameterSetName = "BuildAI")]
    [switch]$BuildAI,

    [Parameter(ParameterSetName = "Validate")]
    [switch]$Validate,

    [Parameter(ParameterSetName = "Preview")]
    [switch]$Preview,

    [Parameter(ParameterSetName = "Status")]
    [switch]$Status,

    [Parameter(ParameterSetName = "Commit")]
    [switch]$Commit,

    [Parameter(ParameterSetName = "Commit")]
    [string]$Message,

    [Parameter(ParameterSetName = "Push")]
    [switch]$Push,

    [Parameter(ParameterSetName = "Deploy")]
    [switch]$Deploy,

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# ZPRINT DEVELOPMENT ORCHESTRATOR
# Version: 0.1.0
# Runtime: PowerShell 7+
#
# Responsibilities:
# - Initialize the repository without overwriting existing files.
# - Validate project configuration and required source files.
# - Run module build checks and generate a build manifest.
# - Open local HTML previews.
# - Report Git status.
# - Commit, push, and deploy only through explicit commands.
#
# Safety:
# - Initialization creates only missing files and directories.
# - Build output is limited to the generated build directory.
# - Git operations are never performed automatically by Build or Validate.
# - Deployment is intentionally disabled until an explicit deployment
#   configuration and publishing workflow have been reviewed.
# ---------------------------------------------------------------------------

$script:ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ProjectName = "ZPRINT"
$script:ProjectVersion = "0.1.0"
$script:ConfigDirectory = Join-Path $script:ProjectRoot "config"
$script:BuildDirectory = Join-Path $script:ProjectRoot "build"
$script:ProjectConfigPath = Join-Path $script:ConfigDirectory "project.json"
$script:BuildConfigPath = Join-Path $script:ConfigDirectory "build.json"
$script:BrandConfigPath = Join-Path $script:ConfigDirectory "brand.json"

function Write-Info {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkCyan
    Write-Host " ZPRINT DEVELOPMENT ORCHESTRATOR" -ForegroundColor White
    Write-Host " Version $script:ProjectVersion" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Success "Created directory: $Path"
    }
    else {
        Write-Info "Directory already exists: $Path"
    }
}

function Write-FileIfMissing {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    if (Test-Path -LiteralPath $Path) {
        Write-WarningMessage "Preserved existing file: $Path"
        return
    }

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding utf8
    Write-Success "Created file: $Path"
}

function Write-GeneratedFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $existing = $null
    if (Test-Path -LiteralPath $Path) {
        $existing = Get-Content -LiteralPath $Path -Raw
    }

    if ($existing -ne $Content) {
        Set-Content -LiteralPath $Path -Value $Content -Encoding utf8
        Write-Success "Updated generated file: $Path"
    }
    else {
        Write-Info "Generated file is unchanged: $Path"
    }
}

function Get-ProjectDirectories {
    return @(
        "config",
        "brand/assets",
        "brand/logo",
        "brand/styles",
        "catalog/data",
        "catalog/products",
        "catalog/assets",
        "catalog/styles",
        "apps/market",
        "apps/business",
        "apps/studio",
        "apps/admin",
        "core/api",
        "core/database",
        "core/identity",
        "core/catalog",
        "core/pricing",
        "core/commerce",
        "core/production",
        "core/inventory",
        "core/infrastructure",
        "ai/architecture",
        "ai/agents",
        "ai/tools",
        "ai/evaluations",
        "ai/handbook",
        "shared/design-system",
        "shared/schemas",
        "shared/contracts",
        "scripts/build",
        "scripts/validate",
        "scripts/deploy",
        "tests",
        "docs/business",
        "docs/technical",
        "docs/decisions",
        "build"
    )
}

function Initialize-Project {
    Write-Info "Initializing ZPRINT at: $script:ProjectRoot"

    foreach ($relativePath in (Get-ProjectDirectories)) {
        $fullPath = Join-Path $script:ProjectRoot $relativePath
        Ensure-Directory -Path $fullPath
    }

    $projectJson = @'
{
  "name": "ZPRINT",
  "version": "0.1.0",
  "description": "Digital Design and Production Platform",
  "language": "en",
  "initial_market": "Colombia",
  "architecture": "modular-monolith",
  "runtime": {
    "powershell": "7+",
    "backend": "Python",
    "frontend": "TypeScript and JavaScript",
    "database": "PostgreSQL"
  },
  "development_tracks": [
    "visual-product",
    "core-engineering"
  ]
}
'@

    $buildJson = @'
{
  "output_directory": "build",
  "modules": {
    "brand": {
      "entrypoint": "brand/brandbook.html"
    },
    "catalog": {
      "entrypoint": "catalog/catalog.html"
    },
    "core": {
      "entrypoint": "core"
    },
    "ai": {
      "entrypoint": "ai"
    }
  },
  "deployment": {
    "enabled": false,
    "provider": "github-pages",
    "branch": "main"
  }
}
'@

    $brandJson = @'
{
  "name": "ZPRINT",
  "descriptor": "Digital Design and Production Platform",
  "tagline": "Design. Visualize. Produce.",
  "language": "en",
  "identity_status": "in-development"
}
'@

    $readme = @'
# ZPRINT

**Digital Design and Production Platform**

ZPRINT is a hybrid SaaS, marketplace, and AI platform for the printing and graphic production industry.

## Development principles

- One repository and one PowerShell orchestrator.
- Modular applications and business domains.
- Shared business core.
- English-only project artifacts.
- Repeatable builds and controlled deployment.
- No automatic Git commits, pushes, or deployments.

## Requirements

- PowerShell 7+
- Git
- A modern web browser

## Getting started

```powershell
pwsh ./zprint.ps1 -Initialize
pwsh ./zprint.ps1 -Validate
pwsh ./zprint.ps1 -Status
```

## Main commands

```powershell
pwsh ./zprint.ps1 -Build
pwsh ./zprint.ps1 -BuildBrand
pwsh ./zprint.ps1 -BuildCatalog
pwsh ./zprint.ps1 -BuildCore
pwsh ./zprint.ps1 -BuildAI
pwsh ./zprint.ps1 -Validate
pwsh ./zprint.ps1 -Preview
pwsh ./zprint.ps1 -Status
pwsh ./zprint.ps1 -Commit -Message "Describe the change"
pwsh ./zprint.ps1 -Push
pwsh ./zprint.ps1 -Deploy
```

## Repository structure

- `brand/`: Brand identity and Brand Book.
- `catalog/`: Product catalog and product definitions.
- `apps/`: Customer and business applications.
- `core/`: Shared business domains and APIs.
- `ai/`: AI architecture, agents, tools, and evaluations.
- `shared/`: Shared design system, schemas, and contracts.
- `docs/`: Business and technical documentation.
- `scripts/`: Supporting build, validation, and deployment scripts.
- `build/`: Generated build reports and artifacts.

## Git safety

Build and validation commands do not stage, commit, push, or deploy changes.

Git operations require explicit commands. Review `git status` and the diff before committing.

## Deployment

Deployment is disabled by default. Configure and review the publishing workflow before enabling it.
'@

    $gitignore = @'
# Operating system
.DS_Store
Thumbs.db

# Editor settings
.vscode/
.idea/

# Environment and secrets
.env
.env.*
!.env.example
*.pem
*.key

# Python
__pycache__/
*.py[cod]
.venv/
venv/
.pytest_cache/

# Node
node_modules/

# Build and temporary files
.tmp/
.temp/
coverage/
'@

    $brandHtml = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="ZPRINT brand identity and design system.">
  <title>ZPRINT — Brand Book</title>
  <link rel="stylesheet" href="styles/brandbook.css">
</head>
<body>
  <main class="brandbook">
    <p class="eyebrow">Brand Identity / Version 1.0</p>
    <h1>ZPRINT</h1>
    <p class="descriptor">Digital Design and Production Platform</p>
    <p class="tagline">Design. Visualize. Produce.</p>
    <p class="status">Brand Book foundation — in development.</p>
  </main>
</body>
</html>
'@

    $brandCss = @'
:root {
  color-scheme: dark;
  font-family: Inter, Arial, sans-serif;
  background: #080b12;
  color: #f5f7fa;
  --zprint-blue: #168bea;
  --zprint-cyan: #23b9ff;
}

* {
  box-sizing: border-box;
}

body {
  min-height: 100vh;
  margin: 0;
  display: grid;
  place-items: center;
  padding: 2rem;
  background: radial-gradient(circle at 50% 40%, #10243a, #080b12 65%);
}

.brandbook {
  width: min(100%, 900px);
  padding: clamp(2rem, 8vw, 6rem);
  border: 1px solid #26384b;
  background: rgba(8, 11, 18, 0.86);
}

.eyebrow,
.status {
  color: #9aabba;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  font-size: 0.75rem;
}

h1 {
  margin: 1.5rem 0 0.5rem;
  font-size: clamp(3.5rem, 12vw, 8rem);
  letter-spacing: -0.08em;
}

.descriptor {
  color: #d5e1ec;
  font-size: clamp(1rem, 2vw, 1.4rem);
}

.tagline {
  margin-top: 3rem;
  color: var(--zprint-cyan);
  font-weight: 700;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}
'@

    $catalogHtml = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="ZPRINT printing products and services catalog.">
  <title>ZPRINT — Product Catalog</title>
  <link rel="stylesheet" href="styles/catalog.css">
</head>
<body>
  <main class="catalog">
    <p class="eyebrow">Product Catalog / Version 1.0</p>
    <h1>ZPRINT</h1>
    <p>Printing products and production services.</p>
    <p class="status">Catalog foundation — in development.</p>
  </main>
</body>
</html>
'@

    $catalogCss = @'
:root {
  color-scheme: dark;
  font-family: Inter, Arial, sans-serif;
  background: #080b12;
  color: #f5f7fa;
}

* {
  box-sizing: border-box;
}

body {
  min-height: 100vh;
  margin: 0;
  padding: 2rem;
  display: grid;
  place-items: center;
  background: #080b12;
}

.catalog {
  width: min(100%, 900px);
  padding: clamp(2rem, 8vw, 6rem);
  border: 1px solid #26384b;
}

.eyebrow,
.status {
  color: #9aabba;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  font-size: 0.75rem;
}

h1 {
  font-size: clamp(3rem, 10vw, 6rem);
  letter-spacing: -0.07em;
}

.status {
  margin-top: 3rem;
}
'@

    Write-FileIfMissing -Path $script:ProjectConfigPath -Content $projectJson
    Write-FileIfMissing -Path $script:BuildConfigPath -Content $buildJson
    Write-FileIfMissing -Path $script:BrandConfigPath -Content $brandJson
    Write-FileIfMissing -Path (Join-Path $script:ProjectRoot "README.md") -Content $readme
    Write-FileIfMissing -Path (Join-Path $script:ProjectRoot ".gitignore") -Content $gitignore
    Write-FileIfMissing -Path (Join-Path $script:ProjectRoot "brand/brandbook.html") -Content $brandHtml
    Write-FileIfMissing -Path (Join-Path $script:ProjectRoot "brand/styles/brandbook.css") -Content $brandCss
    Write-FileIfMissing -Path (Join-Path $script:ProjectRoot "catalog/catalog.html") -Content $catalogHtml
    Write-FileIfMissing -Path (Join-Path $script:ProjectRoot "catalog/styles/catalog.css") -Content $catalogCss

    Write-Success "ZPRINT initialization completed."
}

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required configuration file not found: $Path. Run -Initialize first."
    }

    try {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
    }
    catch {
        throw "Invalid JSON configuration in '$Path': $($_.Exception.Message)"
    }
}

function Test-Project {
    Write-Info "Validating ZPRINT project..."

    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    foreach ($path in @($script:ProjectConfigPath, $script:BuildConfigPath, $script:BrandConfigPath)) {
        if (-not (Test-Path -LiteralPath $path)) {
            $errors.Add("Missing configuration: $path")
        }
    }

    if ($errors.Count -eq 0) {
        $projectConfig = Read-JsonFile -Path $script:ProjectConfigPath
        $null = Read-JsonFile -Path $script:BuildConfigPath
        $null = Read-JsonFile -Path $script:BrandConfigPath

        if ($projectConfig.language -ne "en") {
            $warnings.Add("Project language is not set to English.")
        }
    }

    $requiredFiles = @(
        "README.md",
        "brand/brandbook.html",
        "brand/styles/brandbook.css",
        "catalog/catalog.html",
        "catalog/styles/catalog.css"
    )

    foreach ($relativePath in $requiredFiles) {
        $fullPath = Join-Path $script:ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $fullPath)) {
            $errors.Add("Missing required file: $relativePath")
        }
    }

    if (-not (Test-Command -Name "git")) {
        $warnings.Add("Git was not found. Version-control commands will be unavailable.")
    }

    foreach ($warning in $warnings) {
        Write-WarningMessage $warning
    }

    foreach ($errorMessage in $errors) {
        Write-ErrorMessage $errorMessage
    }

    if ($errors.Count -gt 0) {
        throw "Validation failed with $($errors.Count) error(s)."
    }

    Write-Success "Project validation passed."
}

function Get-ModuleDefinition {
    return @{
        Brand = @{
            Name = "Brand"
            RequiredFiles = @("brand/brandbook.html", "brand/styles/brandbook.css")
        }
        Catalog = @{
            Name = "Catalog"
            RequiredFiles = @("catalog/catalog.html", "catalog/styles/catalog.css")
        }
        Core = @{
            Name = "Core"
            RequiredFiles = @("core")
        }
        AI = @{
            Name = "AI"
            RequiredFiles = @("ai")
        }
    }
}

function Invoke-ModuleBuild {
    param([Parameter(Mandatory)][string[]]$ModuleNames)

    $definitions = Get-ModuleDefinition
    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($moduleName in $ModuleNames) {
        if (-not $definitions.ContainsKey($moduleName)) {
            throw "Unknown build module: $moduleName"
        }

        $definition = $definitions[$moduleName]
        $missing = @()

        foreach ($relativePath in $definition.RequiredFiles) {
            $fullPath = Join-Path $script:ProjectRoot $relativePath
            if (-not (Test-Path -LiteralPath $fullPath)) {
                $missing += $relativePath
            }
        }

        if ($missing.Count -gt 0) {
            throw "Cannot build $moduleName. Missing: $($missing -join ', ')."
        }

        $results.Add([PSCustomObject]@{
            module = $moduleName
            status = "validated"
            timestamp_utc = [DateTime]::UtcNow.ToString("o")
        })

        Write-Success "$($definition.Name) module build check passed."
    }

    Ensure-Directory -Path $script:BuildDirectory

    $manifest = [PSCustomObject]@{
        project = $script:ProjectName
        version = $script:ProjectVersion
        generated_at_utc = [DateTime]::UtcNow.ToString("o")
        modules = @($results)
        note = "V0.1 build manifest. Module checks are implemented; production bundling is not configured yet."
    }

    $manifestJson = $manifest | ConvertTo-Json -Depth 8
    Write-GeneratedFile -Path (Join-Path $script:BuildDirectory "manifest.json") -Content $manifestJson

    Write-Success "Build checks completed. No Git operations were performed."
}

function Invoke-FullBuild {
    Test-Project
    Invoke-ModuleBuild -ModuleNames @("Brand", "Catalog", "Core", "AI")
}

function Open-Preview {
    $previewPath = Join-Path $script:ProjectRoot "brand/brandbook.html"

    if (-not (Test-Path -LiteralPath $previewPath)) {
        throw "Brand Book entry point not found. Run -Initialize first."
    }

    $uri = ([System.Uri]$previewPath).AbsoluteUri
    Write-Info "Opening local preview: $previewPath"

    if ($IsMacOS) {
        if (Test-Command -Name "open") {
            & open $uri
        }
        else {
            Write-WarningMessage "The 'open' command is unavailable. Open this file manually: $previewPath"
        }
    }
    elseif ($IsWindows) {
        Start-Process $uri
    }
    elseif ($IsLinux) {
        if (Test-Command -Name "xdg-open") {
            & xdg-open $uri
        }
        else {
            Write-WarningMessage "The 'xdg-open' command is unavailable. Open this file manually: $previewPath"
        }
    }
    else {
        Write-WarningMessage "Automatic preview is unsupported on this operating system."
    }
}

function Invoke-Git {
    param([Parameter(Mandatory)][string[]]$Arguments)

    if (-not (Test-Command -Name "git")) {
        throw "Git is not installed or is not available in PATH."
    }

    Push-Location $script:ProjectRoot
    try {
        & git @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Git command failed: git $($Arguments -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Get-GitStatus {
    if (-not (Test-Command -Name "git")) {
        Write-WarningMessage "Git is not installed."
        return
    }

    Push-Location $script:ProjectRoot
    try {
        & git rev-parse --is-inside-work-tree *> $null
        if ($LASTEXITCODE -ne 0) {
            Write-WarningMessage "The project directory is not a Git repository."
            return
        }

        Write-Info "Current branch:"
        & git branch --show-current

        Write-Info "Working tree:"
        & git status --short --branch
    }
    finally {
        Pop-Location
    }
}

function Invoke-Commit {
    if ([string]::IsNullOrWhiteSpace($Message)) {
        throw "A commit message is required. Example: -Commit -Message 'Update brand foundation'"
    }

    if (-not (Test-Command -Name "git")) {
        throw "Git is not installed or is not available in PATH."
    }

    Push-Location $script:ProjectRoot
    try {
        & git rev-parse --is-inside-work-tree *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "This directory is not a Git repository. Initialize Git separately before committing."
        }

        & git status --short
        Write-WarningMessage "The next operation stages all changes in this repository."
        if (-not $Force) {
            $confirmation = Read-Host "Review your changes. Continue with git add -A and commit? (y/N)"
            if ($confirmation -notin @("y", "Y", "yes", "YES")) {
                Write-Info "Commit cancelled."
                return
            }
        }

        & git add -A
        if ($LASTEXITCODE -ne 0) {
            throw "Git staging failed."
        }

        & git commit -m $Message
        if ($LASTEXITCODE -ne 0) {
            throw "Git commit failed. Check whether there are changes to commit."
        }

        Write-Success "Commit created."
    }
    finally {
        Pop-Location
    }
}

function Invoke-Push {
    if (-not (Test-Command -Name "git")) {
        throw "Git is not installed or is not available in PATH."
    }

    Push-Location $script:ProjectRoot
    try {
        & git rev-parse --is-inside-work-tree *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "This directory is not a Git repository."
        }

        $branch = (& git branch --show-current).Trim()
        if ([string]::IsNullOrWhiteSpace($branch)) {
            throw "No current branch is checked out."
        }

        $statusOutput = @(& git status --porcelain)
        if ($statusOutput.Count -gt 0) {
            throw "Working tree is not clean. Commit or stash changes before pushing."
        }

        Write-Info "Target: origin/$branch"
        if (-not $Force) {
            $confirmation = Read-Host "Push the current branch to origin? (y/N)"
            if ($confirmation -notin @("y", "Y", "yes", "YES")) {
                Write-Info "Push cancelled."
                return
            }
        }

        & git push origin $branch
        if ($LASTEXITCODE -ne 0) {
            throw "Git push failed."
        }

        Write-Success "Push completed."
    }
    finally {
        Pop-Location
    }
}

function Invoke-Deploy {
    $buildConfig = Read-JsonFile -Path $script:BuildConfigPath

    if (-not $buildConfig.deployment.enabled) {
        Write-WarningMessage "Deployment is disabled in config/build.json."
        Write-Info "Configure and review the publishing workflow before enabling deployment."
        return
    }

    throw "Deployment execution is not implemented in ZPRINT $script:ProjectVersion. Configure and test a dedicated deployment workflow before enabling this command."
}

function Show-Help {
    @'
ZPRINT DEVELOPMENT ORCHESTRATOR

Usage:
  pwsh ./zprint.ps1 -Initialize
  pwsh ./zprint.ps1 -Build
  pwsh ./zprint.ps1 -BuildBrand
  pwsh ./zprint.ps1 -BuildCatalog
  pwsh ./zprint.ps1 -BuildCore
  pwsh ./zprint.ps1 -BuildAI
  pwsh ./zprint.ps1 -Validate
  pwsh ./zprint.ps1 -Preview
  pwsh ./zprint.ps1 -Status
  pwsh ./zprint.ps1 -Commit -Message "Describe the change"
  pwsh ./zprint.ps1 -Push
  pwsh ./zprint.ps1 -Deploy

Options:
  -Force    Skip confirmation prompts for explicitly requested Git actions.
            This option never makes Build or Validate perform Git operations.

Examples:
  pwsh ./zprint.ps1 -Initialize
  pwsh ./zprint.ps1 -Build
  pwsh ./zprint.ps1 -Commit -Message "Add initial ZPRINT foundation"

All project artifacts must be written in English.
Build and validation never commit, push, or deploy automatically.
'@ | Write-Host
}

# ---------------------------------------------------------------------------
# Command dispatch
# ---------------------------------------------------------------------------

try {
    Write-Header

    switch ($PSCmdlet.ParameterSetName) {
        "Initialize" {
            Initialize-Project
        }
        "Build" {
            Invoke-FullBuild
        }
        "BuildBrand" {
            Test-Project
            Invoke-ModuleBuild -ModuleNames @("Brand")
        }
        "BuildCatalog" {
            Test-Project
            Invoke-ModuleBuild -ModuleNames @("Catalog")
        }
        "BuildCore" {
            Test-Project
            Invoke-ModuleBuild -ModuleNames @("Core")
        }
        "BuildAI" {
            Test-Project
            Invoke-ModuleBuild -ModuleNames @("AI")
        }
        "Validate" {
            Test-Project
        }
        "Preview" {
            Open-Preview
        }
        "Status" {
            Get-GitStatus
        }
        "Commit" {
            Invoke-Commit
        }
        "Push" {
            Invoke-Push
        }
        "Deploy" {
            Invoke-Deploy
        }
        default {
            Show-Help
        }
    }
}
catch {
    Write-ErrorMessage $_.Exception.Message
    exit 1
}
