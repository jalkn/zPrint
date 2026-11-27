
#requires -Version 7.0

<#
.SYNOPSIS
    ZPRINT STUDIO project orchestrator.

.DESCRIPTION
    Provides project metadata, command-line operations,
    environment diagnostics, and safe project initialization.

.NOTES
    Project:       ZPRINT STUDIO
    Version:       0.1.0
    Milestone:     Project Initialization
    Orchestrator:  zprint.ps1

    This is the permanent project orchestrator.
    All future development must extend this file.
#>

[CmdletBinding(DefaultParameterSetName = 'Help')]
param (
    [Parameter(ParameterSetName = 'Help')]
    [switch]$Help,

    [Parameter(ParameterSetName = 'Version')]
    [switch]$Version,

    [Parameter(ParameterSetName = 'Status')]
    [switch]$Status,

    [Parameter(ParameterSetName = 'Doctor')]
    [switch]$Doctor,

    [Parameter(ParameterSetName = 'Initialize')]
    [switch]$Initialize
)

# ============================================================
# 01. PROJECT METADATA
# ============================================================

$script:Project = [ordered]@{
    Name        = 'ZPRINT'
    Product     = 'ZPRINT STUDIO'
    Description = 'Digital Design & Production Platform'
    Version     = '0.1.0'
    Milestone   = 'Project Initialization'
    Script      = 'zprint.ps1'
}

# Resolve the project root from the location of this script.
$script:ProjectRoot = $PSScriptRoot

# Define the permanent brand asset destinations.
# Source files in the project root are only needed for first setup.
$script:BrandAssets = @(
    @{
        Source      = 'zPrint.svg'
        Destination = 'zPrint.svg'
    },
    @{
        Source      = 'brandBookover.png'
        Destination = 'brandBookCover.png'
    },
    @{
        Source      = 'logoGeometry.png'
        Destination = 'logoGeometry.png'
    }
)

# ============================================================
# 02. OUTPUT HELPERS
# ============================================================

function Write-Header {
    param (
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ''
    Write-Host 'ZPRINT STUDIO'
    Write-Host $Title
    Write-Host ('-' * 60)
}

function Write-Info {
    param (
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$Value
    )

    Write-Host ('{0,-24} {1}' -f "${Label}:", $Value)
}

# ============================================================
# 03. COMMAND HANDLERS
# ============================================================

function Show-Help {
    Write-Header -Title 'Command-line interface'

    Write-Host ''
    Write-Host 'USAGE'
    Write-Host '  pwsh -File ./zprint.ps1 -<Command>'
    Write-Host '  pwsh -File ./zprint.ps1'
    Write-Host ''

    Write-Host 'COMMANDS'
    Write-Host '  -Help        Display help information.'
    Write-Host '  -Version     Display project version.'
    Write-Host '  -Status      Display project status.'
    Write-Host '  -Doctor      Run environment diagnostics.'
    Write-Host '  -Initialize  Initialize the project structure.'
    Write-Host ''

    Write-Host 'EXAMPLES'
    Write-Host '  pwsh -File ./zprint.ps1 -Help'
    Write-Host '  pwsh -File ./zprint.ps1 -Version'
    Write-Host '  pwsh -File ./zprint.ps1 -Status'
    Write-Host '  pwsh -File ./zprint.ps1 -Doctor'
    Write-Host '  pwsh -File ./zprint.ps1 -Initialize'
    Write-Host ''

    Write-Host 'NOTES'
    Write-Host '  Select exactly one command.'
    Write-Host '  Running without a command displays help.'
    Write-Host '  Git operations remain independent.'
}

function Show-Version {
    Write-Header -Title 'Version information'

    Write-Info -Label 'Project' -Value $script:Project.Name
    Write-Info -Label 'Product' -Value $script:Project.Product
    Write-Info -Label 'Version' -Value $script:Project.Version
    Write-Info -Label 'Milestone' -Value $script:Project.Milestone
    Write-Info -Label 'Script' -Value $script:Project.Script
}

function Show-Status {
    Write-Header -Title 'Project status'

    $scriptExists = Test-Path -LiteralPath (
        Join-Path $script:ProjectRoot $script:Project.Script
    ) -PathType Leaf

    $initialized = Test-Path -LiteralPath (
        Join-Path $script:ProjectRoot 'config/project.json'
    ) -PathType Leaf

    $assetsDirectory = Join-Path $script:ProjectRoot 'brand/assets'

    $assetCount = 0

    foreach ($asset in $script:BrandAssets) {
        $assetPath = Join-Path $assetsDirectory $asset.Destination

        if (Test-Path -LiteralPath $assetPath -PathType Leaf) {
            $assetCount++
        }
    }

    Write-Info -Label 'Project' -Value $script:Project.Name
    Write-Info -Label 'Version' -Value $script:Project.Version
    Write-Info -Label 'Milestone' -Value $script:Project.Milestone
    Write-Info -Label 'Project root' -Value $script:ProjectRoot
    Write-Info -Label 'Script present' -Value $scriptExists
    Write-Info -Label 'Initialized' -Value $initialized
    Write-Info -Label 'Brand assets' -Value "$assetCount / $($script:BrandAssets.Count)"

    Write-Host ''
    Write-Host 'This command does not modify project files.'
}

function Show-Doctor {
    Write-Header -Title 'Environment diagnostics'

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue

    $gitPath = if ($gitCommand) {
        $gitCommand.Source
    }
    else {
        'Not detected'
    }

    Write-Info -Label 'PowerShell' -Value $PSVersionTable.PSVersion.ToString()
    Write-Info -Label 'Platform' -Value $PSVersionTable.OS
    Write-Info -Label 'Git executable' -Value $gitPath
    Write-Info -Label 'Project root' -Value $script:ProjectRoot
    Write-Info -Label 'External modules' -Value 'None required'

    Write-Host ''
    Write-Host 'Diagnostics do not execute Git commands or install dependencies.'
}

# ============================================================
# 04. PROJECT INITIALIZATION
# ============================================================

function Initialize-Project {

    Write-Header -Title 'Project initialization'

    # Define the initial directory structure.
    $brandDirectory = Join-Path $script:ProjectRoot 'brand'
    $assetsDirectory = Join-Path $brandDirectory 'assets'
    $configDirectory = Join-Path $script:ProjectRoot 'config'

    $configPath = Join-Path $configDirectory 'project.json'

    # --------------------------------------------------------
    # STEP 1: Inspect source and destination assets.
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'STEP 1 — Brand asset inspection'

    $assetPlan = @()
    $missingAssets = @()

    foreach ($asset in $script:BrandAssets) {

        $sourcePath = Join-Path $script:ProjectRoot $asset.Source

        $destinationPath = Join-Path $assetsDirectory $asset.Destination

        $sourceExists = Test-Path -LiteralPath $sourcePath -PathType Leaf

        $destinationExists = Test-Path -LiteralPath $destinationPath -PathType Leaf

        if (-not $sourceExists -and -not $destinationExists) {
            $missingAssets += $asset.Destination
            continue
        }

        $action = 'Preserve'

        # If both copies exist, verify that their contents match.
        if ($sourceExists -and $destinationExists) {

            $sourceHash = (
                Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256
            ).Hash

            $destinationHash = (
                Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256
            ).Hash

            if ($sourceHash -ne $destinationHash) {
                throw "Asset conflict detected: $destinationPath"
            }

            Write-Info -Label 'Already identical' -Value $asset.Destination
        }
        elseif ($sourceExists -and -not $destinationExists) {

            $action = 'Copy'

            Write-Info -Label 'Source available' -Value $asset.Source
        }
        else {

            # The permanent destination already exists.
            # The original source file is no longer required.
            Write-Info -Label 'Installed asset found' -Value $asset.Destination
        }

        $assetPlan += @{
            SourcePath      = $sourcePath
            DestinationPath = $destinationPath
            Action          = $action
            SourceExists    = $sourceExists
        }
    }

    if ($missingAssets.Count -gt 0) {
        throw (
            'Missing brand assets in both source and destination: ' +
            ($missingAssets -join ', ')
        )
    }

    # --------------------------------------------------------
    # STEP 2: Validate existing configuration.
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'STEP 2 — Configuration validation'

    if (Test-Path -LiteralPath $configPath -PathType Leaf) {

        try {
            $existingConfig = Get-Content -LiteralPath $configPath -Raw |
                ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw 'Existing project.json is not valid JSON.'
        }

        if ($null -eq $existingConfig) {
            throw 'Existing project.json is empty or invalid.'
        }

        Write-Host 'Existing configuration will be preserved.'
    }

    # --------------------------------------------------------
    # STEP 3: Create required directories.
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'STEP 3 — Directory creation'

    $directories = @(
        $brandDirectory,
        $assetsDirectory,
        $configDirectory
    )

    foreach ($directory in $directories) {

        New-Item `
            -ItemType Directory `
            -Path $directory `
            -Force `
            -ErrorAction Stop |
            Out-Null

        Write-Info -Label 'Directory ready' -Value $directory
    }

    # --------------------------------------------------------
    # STEP 4: Integrate brand assets.
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'STEP 4 — Brand asset integration'

    foreach ($item in $assetPlan) {

        if ($item.Action -eq 'Copy') {

            Copy-Item `
                -LiteralPath $item.SourcePath `
                -Destination $item.DestinationPath `
                -ErrorAction Stop

            Write-Info `
                -Label 'Copied' `
                -Value ([System.IO.Path]::GetFileName($item.DestinationPath))
        }
        else {

            Write-Info `
                -Label 'Preserved' `
                -Value ([System.IO.Path]::GetFileName($item.DestinationPath))
        }
    }

    # --------------------------------------------------------
    # STEP 5: Create initial project configuration.
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'STEP 5 — Project configuration'

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {

        $configuration = [ordered]@{
            project = [ordered]@{
                name         = $script:Project.Name
                product      = $script:Project.Product
                description  = $script:Project.Description
                version      = $script:Project.Version
                milestone    = $script:Project.Milestone
                orchestrator = $script:Project.Script
            }
        }

        $json = $configuration | ConvertTo-Json -Depth 5

        Set-Content `
            -LiteralPath $configPath `
            -Value $json `
            -Encoding utf8 `
            -NoNewline `
            -ErrorAction Stop

        Write-Info -Label 'Created' -Value 'config/project.json'
    }
    else {

        Write-Host 'Existing project.json preserved.'
    }

    # --------------------------------------------------------
    # STEP 6: Validate initialization results.
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'STEP 6 — Initialization verification'

    foreach ($asset in $script:BrandAssets) {

        $destinationPath = Join-Path $assetsDirectory $asset.Destination

        if (-not (Test-Path -LiteralPath $destinationPath -PathType Leaf)) {
            throw "Initialization validation failed: $destinationPath"
        }

        # Verify content integrity when the original is available.
        $sourcePath = Join-Path $script:ProjectRoot $asset.Source

        if (Test-Path -LiteralPath $sourcePath -PathType Leaf) {

            $sourceHash = (
                Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256
            ).Hash

            $destinationHash = (
                Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256
            ).Hash

            if ($sourceHash -ne $destinationHash) {
                throw "Asset integrity verification failed: $destinationPath"
            }
        }
    }

    # Verify the final configuration is valid JSON.
    Get-Content -LiteralPath $configPath -Raw |
        ConvertFrom-Json -ErrorAction Stop |
        Out-Null

    Write-Host ''
    Write-Host 'PROJECT INITIALIZATION COMPLETED'
    Write-Host ''

    Write-Info -Label 'Brand assets' -Value '3 verified'
    Write-Info -Label 'Configuration' -Value 'Valid JSON'
    Write-Info -Label 'Project root' -Value $script:ProjectRoot
}

# ============================================================
# 05. COMMAND ROUTER
# ============================================================

try {

    switch ($PSCmdlet.ParameterSetName) {

        'Help' {
            Show-Help
        }

        'Version' {
            Show-Version
        }

        'Status' {
            Show-Status
        }

        'Doctor' {
            Show-Doctor
        }

        'Initialize' {
            Initialize-Project
        }

        default {
            Show-Help
        }
    }

    # Return exit code 0 when the selected command completes.
    exit 0
}
catch {

    # Report runtime errors through the standard error stream.
    [Console]::Error.WriteLine(
        "ZPRINT ERROR: $($_.Exception.Message)"
    )

    # Return exit code 1 when execution fails.
    exit 1
}
