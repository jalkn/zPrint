#requires -Version 7.0

# ============================================================================== 
#
#   ███████╗██████╗ ██████╗ ██╗███╗   ██╗████████╗
#   ╚══███╔╝██╔══██╗██╔══██╗██║████╗  ██║╚══██╔══╝
#     ███╔╝ ██████╔╝██████╔╝██║██╔██╗ ██║   ██║
#    ███╔╝  ██╔═══╝ ██╔══██╗██║██║╚██╗██║   ██║
#   ███████╗██║     ██║  ██║██║██║ ╚████║   ██║
#   ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝
#
#   ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗
#   ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗
#   ███████╗   ██║   ██║   ██║██║  ██║██║   ██║
#   ╚════██║   ██║   ██║   ██║██║  ██║██║   ██║
#   ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝
#   ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝
#
#   ZPRINT STUDIO
#   DIGITAL DESIGN & PRODUCTION PLATFORM
#
#   DESIGN. VISUALIZE. PRODUCE.
#
#   SINGLE-FILE PLATFORM GENERATOR
#
#   PowerShell 7+
#
#   Version:   0.1.0
#   Milestone: 03 — Project Architecture & State Management
#
# ============================================================================== 

<#
.SYNOPSIS
    ZPRINT STUDIO single-file platform generator.

.DESCRIPTION
    Generates, updates, validates, and maintains the ZPRINT platform.

    ARCHITECTURE PRINCIPLES
    - One permanent PowerShell orchestrator.
    - Modular internal architecture.
    - Progressive and idempotent implementation.
    - Explicit file protection and overwrite policies.
    - Centralized validation, diagnostics, and error handling.
    - Git operations remain external to this script.

    RUNTIME FOUNDATION
    - Centralized exit codes and output.
    - PowerShell and operating-system detection.
    - Project-root resolution independent of the caller's directory.
    - Append-only diagnostic logging when required.

    PROJECT STRUCTURE REGISTRY
    - Centralized canonical project paths.
    - Explicit required, optional, and planned directories.
    - Future directories remain deferred until their implementation milestone.

.PARAMETER Help
    Display the command help information.

.PARAMETER Version
    Display the generator version and milestone.

.NOTES
    Project:       ZPRINT
    Platform:      ZPRINT STUDIO
    Positioning:   DIGITAL DESIGN & PRODUCTION PLATFORM
    Orchestrator:  zprint.ps1
    Version:       0.1.0
    Milestone:     Project Architecture & State Management
#>

# ==============================================================================
# 02. PARAMETER DECLARATION
# ==============================================================================

param(
    [switch]$Help,
    [switch]$Version,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArguments
)

# ==============================================================================
# 03. PROJECT METADATA AND RUNTIME CONSTANTS
# ==============================================================================

$script:ZprintVersion = '0.1.0'
$script:ZprintMilestone = '03 — Project Architecture & State Management'

$script:ZprintExitCodes = @{
    Success          = 0
    GeneralError     = 1
    InvalidArguments = 2
    EnvironmentError = 3
}

$script:ZprintProjectRoot = $null
$script:ZprintPaths = $null
$script:ZprintLogPath = $null

# ==============================================================================
# 04. OUTPUT MANAGEMENT
# ==============================================================================

function Write-ZprintInfo {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "INFO: $Message" -ForegroundColor Cyan
}

function Write-ZprintWarning {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

function Write-ZprintError {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "ERROR: $Message" -ForegroundColor Red
}

# ==============================================================================
# 05. ENVIRONMENT DETECTION
# ==============================================================================

function Get-ZprintRuntimeEnvironment {
    $operatingSystem = if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows
    )) {
        'Windows'
    }
    elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::OSX
    )) {
        'macOS'
    }
    elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Linux
    )) {
        'Linux'
    }
    else {
        'Unknown'
    }

    [pscustomobject]@{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Edition           = $PSVersionTable.PSEdition
        OperatingSystem   = $operatingSystem
        Platform          = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        ProcessArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()
    }
}

# ==============================================================================
# 06. PROJECT STRUCTURE REGISTRY
# ==============================================================================

function Get-ZprintProjectPaths {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $root = [System.IO.Path]::GetFullPath($ProjectRoot)

    [pscustomobject][ordered]@{
        ProjectRoot             = $root
        Orchestrator            = Join-Path $root 'zprint.ps1'

        ConfigDirectory         = Join-Path $root 'config'
        ProjectConfiguration    = Join-Path $root 'config/project.json'
        CatalogConfiguration    = Join-Path $root 'config/catalog.json'

        BrandDirectory          = Join-Path $root 'brand'
        BrandAssetsDirectory    = Join-Path $root 'brand/assets'
        BrandLogo               = Join-Path $root 'brand/assets/zPrint.svg'
        BrandBookCover          = Join-Path $root 'brand/assets/brandBookCover.png'
        BrandLogoGeometry       = Join-Path $root 'brand/assets/logoGeometry.png'
        BrandDocumentation      = Join-Path $root 'brand/documentation'

        PlatformDirectory       = Join-Path $root 'platform'
        FrontendDirectory       = Join-Path $root 'platform/frontend'
        BackendDirectory        = Join-Path $root 'platform/backend'
        SharedDirectory         = Join-Path $root 'platform/shared'

        DataDirectory           = Join-Path $root 'data'
        DataSchemasDirectory    = Join-Path $root 'data/schemas'
        DataSeedsDirectory      = Join-Path $root 'data/seeds'

        DocumentationDirectory  = Join-Path $root 'documentation'
        BuildDirectory          = Join-Path $root 'build'

        LogsDirectory           = Join-Path $root 'logs'
        LogFile                 = Join-Path $root 'logs/zprint.log'
    }
}

function Get-ZprintProjectStructure {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $paths = Get-ZprintProjectPaths -ProjectRoot $ProjectRoot

    # Required directories form the minimum project foundation.
    # Optional directories are created only when their owning capability needs them.
    # Planned directories are documented targets and are not created in this block.
    $structureDefinitions = @(
        [pscustomobject]@{
            Id = 'Configuration'
            RelativePath = 'config'
            Requirement = 'Required'
            Lifecycle = 'Foundation'
            CreationPolicy = 'CreateIfMissing'
            Purpose = 'Project and platform configuration'
        }
        [pscustomobject]@{
            Id = 'Brand'
            RelativePath = 'brand'
            Requirement = 'Required'
            Lifecycle = 'Foundation'
            CreationPolicy = 'CreateIfMissing'
            Purpose = 'Brand identity resources'
        }
        [pscustomobject]@{
            Id = 'BrandAssets'
            RelativePath = 'brand/assets'
            Requirement = 'Required'
            Lifecycle = 'Foundation'
            CreationPolicy = 'CreateIfMissing'
            Purpose = 'Installed authoritative brand assets'
        }
        [pscustomobject]@{
            Id = 'Logs'
            RelativePath = 'logs'
            Requirement = 'Optional'
            Lifecycle = 'Runtime'
            CreationPolicy = 'CreateOnDemand'
            Purpose = 'Append-only generator diagnostics'
        }
        [pscustomobject]@{
            Id = 'BrandDocumentation'
            RelativePath = 'brand/documentation'
            Requirement = 'Planned'
            Lifecycle = 'Future'
            CreationPolicy = 'Deferred'
            Purpose = 'Brand guidelines and identity documentation'
        }
        [pscustomobject]@{
            Id = 'Frontend'
            RelativePath = 'platform/frontend'
            Requirement = 'Planned'
            Lifecycle = 'Future'
            CreationPolicy = 'Deferred'
            Purpose = 'Customer-facing portal application'
        }
        [pscustomobject]@{
            Id = 'Backend'
            RelativePath = 'platform/backend'
            Requirement = 'Planned'
            Lifecycle = 'Future'
            CreationPolicy = 'Deferred'
            Purpose = 'Application services and API'
        }
        [pscustomobject]@{
            Id = 'Shared'
            RelativePath = 'platform/shared'
            Requirement = 'Planned'
            Lifecycle = 'Future'
            CreationPolicy = 'Deferred'
            Purpose = 'Shared platform contracts and resources'
        }
        [pscustomobject]@{
            Id = 'DataSchemas'
            RelativePath = 'data/schemas'
            Requirement = 'Planned'
            Lifecycle = 'Future'
            CreationPolicy = 'Deferred'
            Purpose = 'Data and configuration schemas'
        }
        [pscustomobject]@{
            Id = 'DataSeeds'
            RelativePath = 'data/seeds'
            Requirement = 'Planned'
            Lifecycle = 'Future'
            CreationPolicy = 'Deferred'
            Purpose = 'Initial and reference data'
        }
        [pscustomobject]@{
            Id = 'Documentation'
            RelativePath = 'documentation'
            Requirement = 'Planned'
            Lifecycle = 'Future'
            CreationPolicy = 'Deferred'
            Purpose = 'Technical and product documentation'
        }
        [pscustomobject]@{
            Id = 'Build'
            RelativePath = 'build'
            Requirement = 'Planned'
            Lifecycle = 'Future'
            CreationPolicy = 'Deferred'
            Purpose = 'Generated build and validation artifacts'
        }
    )

    foreach ($definition in $structureDefinitions) {
        $fullPath = Join-Path $paths.ProjectRoot $definition.RelativePath

        [pscustomobject]@{
            Id = $definition.Id
            RelativePath = $definition.RelativePath
            FullPath = [System.IO.Path]::GetFullPath($fullPath)
            Requirement = $definition.Requirement
            Lifecycle = $definition.Lifecycle
            CreationPolicy = $definition.CreationPolicy
            Purpose = $definition.Purpose
        }
    }
}

function Get-ZprintProjectRoot {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        return [System.IO.Path]::GetFullPath($PSScriptRoot)
    }

    return [System.IO.Path]::GetFullPath((Get-Location).Path)
}

function Initialize-ZprintRuntimePaths {
    $script:ZprintProjectRoot = Get-ZprintProjectRoot
    $script:ZprintPaths = Get-ZprintProjectPaths -ProjectRoot $script:ZprintProjectRoot
    $script:ZprintLogPath = $script:ZprintPaths.LogFile
}

# ==============================================================================
# 07. LOGGING FOUNDATION
# ==============================================================================

function Write-ZprintLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($script:ZprintLogPath)) {
        Initialize-ZprintRuntimePaths
    }

    $logDirectory = Split-Path -Parent $script:ZprintLogPath

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $logDirectory -Force -ErrorAction Stop |
            Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffK'
    $entry = '{0} [{1}] {2}{3}' -f $timestamp, $Level, $Message, [Environment]::NewLine

    [System.IO.File]::AppendAllText(
        $script:ZprintLogPath,
        $entry,
        [System.Text.UTF8Encoding]::new($false)
    )
}

# ==============================================================================
# 08. COMMAND HANDLERS
# ==============================================================================

function Show-ZprintHelp {
    $helpText = @'
ZPRINT STUDIO
DIGITAL DESIGN & PRODUCTION PLATFORM
DESIGN. VISUALIZE. PRODUCE.

SINGLE-FILE PLATFORM GENERATOR
Version 0.1.0 | Milestone 03 — Project Architecture & State Management

USAGE
  ./zprint.ps1 -Help
  ./zprint.ps1 -Version
  ./zprint.ps1

AVAILABLE COMMANDS
  -Help       Display this help information.
  -Version    Display version and milestone information.

The generator is under progressive development.
Additional commands will be introduced in subsequent milestones.
'@

    Write-Host $helpText
}

function Show-ZprintVersion {
    Write-ZprintInfo 'ZPRINT STUDIO'
    Write-Host "Version:   $script:ZprintVersion"
    Write-Host "Milestone: $script:ZprintMilestone"

    $environment = Get-ZprintRuntimeEnvironment
    Write-Host "PowerShell: $($environment.PowerShellVersion) ($($environment.Edition))"
    Write-Host "OS:         $($environment.OperatingSystem)"
}

# ==============================================================================
# 09. COMMAND VALIDATION
# ==============================================================================

function Get-ZprintCommandState {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$BoundParameters,

        [string[]]$UnexpectedArguments
    )

    $supportedCommands = @('Help', 'Version')

    $selectedCommands = @(
        foreach ($commandName in $supportedCommands) {
            if ($BoundParameters.Keys -contains $commandName) {
                $commandName
            }
        }
    )

    # PowerShell may pass an empty placeholder when no remaining
    # positional arguments were supplied. Ignore null and whitespace values.
    $effectiveUnexpectedArguments = @(
        $UnexpectedArguments | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        }
    )

    if ($effectiveUnexpectedArguments.Count -gt 0) {
        return [pscustomobject]@{
            IsValid      = $false
            Command      = $null
            ErrorMessage = "Unexpected positional argument(s): $($effectiveUnexpectedArguments -join ', ')"
        }
    }

    if ($selectedCommands.Count -gt 1) {
        return [pscustomobject]@{
            IsValid      = $false
            Command      = $null
            ErrorMessage = 'Only one command can be specified per execution.'
        }
    }

    if ($selectedCommands.Count -eq 0) {
        return [pscustomobject]@{
            IsValid      = $true
            Command      = 'Help'
            ErrorMessage = $null
        }
    }

    return [pscustomobject]@{
        IsValid      = $true
        Command      = $selectedCommands[0]
        ErrorMessage = $null
    }
}

# ==============================================================================
# 10. MAIN EXECUTION AND ERROR HANDLING
# ==============================================================================

try {
    $commandState = Get-ZprintCommandState `
        -BoundParameters $PSBoundParameters `
        -UnexpectedArguments $RemainingArguments

    if (-not $commandState.IsValid) {
        Write-ZprintError $commandState.ErrorMessage

        try {
            Initialize-ZprintRuntimePaths
            Write-ZprintLog -Level 'ERROR' -Message $commandState.ErrorMessage
        }
        catch {
            Write-ZprintWarning "Could not write the diagnostic log: $($_.Exception.Message)"
        }

        exit $script:ZprintExitCodes.InvalidArguments
    }

    switch ($commandState.Command) {
        'Help' {
            Show-ZprintHelp
            exit $script:ZprintExitCodes.Success
        }

        'Version' {
            Initialize-ZprintRuntimePaths
            Show-ZprintVersion
            exit $script:ZprintExitCodes.Success
        }
    }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-ZprintError $errorMessage

    try {
        Initialize-ZprintRuntimePaths
        Write-ZprintLog -Level 'ERROR' -Message $errorMessage
    }
    catch {
        Write-ZprintWarning "Could not write the diagnostic log: $($_.Exception.Message)"
    }

    exit $script:ZprintExitCodes.GeneralError
}
