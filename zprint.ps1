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

#requires -Version 7.0

<#
.SYNOPSIS
    ZPRINT STUDIO single-file platform orchestrator.

.DESCRIPTION
    ZPRINT STUDIO is a DIGITAL DESIGN & PRODUCTION PLATFORM.

    This script is the central control point for generating,
    updating, validating, and maintaining the entire ZPRINT platform.

    ARCHITECTURE PRINCIPLES
    - Single permanent PowerShell orchestrator.
    - All project logic remains inside this file.
    - Internally modular architecture with defined responsibilities.
    - Generated files and assets may be organized into separate directories.
    - Existing user data and configuration must be preserved.
    - Operations must be idempotent.
    - Every operation must support validation and logging.

    PLATFORM RESPONSIBILITIES
    - Project Core and Configuration.
    - Platform and File Generation.
    - Brand Management.
    - Product Catalog Management.
    - Application Generation.
    - AI Agent Integration.
    - Documentation Generation.
    - Validation and Diagnostics.
    - Logging and Command Routing.

    DEVELOPMENT PRINCIPLES
    - Extend this permanent file; never create versioned orchestrators.
    - Implement capabilities progressively.
    - Validate each implementation before advancing.
    - Avoid unnecessary external dependencies.
    - Never overwrite existing user data silently.

.PARAMETER Help
    Display the command help information.

.PARAMETER Version
    Display the generator version and milestone.

.NOTES
    Project:       ZPRINT STUDIO
    Positioning:   DIGITAL DESIGN & PRODUCTION PLATFORM
    Version:       0.1.0
    Milestone:     Project Architecture
    Orchestrator:  zprint.ps1
    Architecture: Single-File Platform Generator
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
# 07. CONFIGURATION MANAGEMENT
# ==============================================================================

function Get-ZprintDefaultProjectConfiguration {
    # This is an in-memory reference only. It does not create or modify files.
    [ordered]@{
        project = [ordered]@{
            name        = 'ZPRINT'
            product     = 'ZPRINT STUDIO'
            description = 'Digital Design & Production Platform'
            version     = '0.1.0'
            milestone   = 'Project Architecture'
            orchestrator = 'zprint.ps1'
        }
    }
}

function ConvertFrom-ZprintProjectJson {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$JsonContent
    )

    # Parsing is isolated so callers can handle JSON errors consistently.
    ConvertFrom-Json `
        -InputObject $JsonContent `
        -AsHashtable `
        -ErrorAction Stop
}

function Read-ZprintProjectConfiguration {
    if ($null -eq $script:ZprintPaths) {
        Initialize-ZprintRuntimePaths
    }

    $configurationPath = $script:ZprintPaths.ProjectConfiguration

    if (-not (Test-Path -LiteralPath $configurationPath)) {
        return [pscustomobject]@{
            Status        = 'Missing'
            Path          = $configurationPath
            Configuration = $null
            ErrorMessage  = $null
        }
    }

    try {
        $configurationItem = Get-Item -LiteralPath $configurationPath -ErrorAction Stop

        if ($configurationItem.PSIsContainer) {
            return [pscustomobject]@{
                Status        = 'Invalid'
                Path          = $configurationPath
                Configuration = $null
                ErrorMessage  = 'The project configuration path exists but is not a file.'
            }
        }

        $jsonContent = Get-Content -LiteralPath $configurationPath -Raw -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($jsonContent)) {
            return [pscustomobject]@{
                Status        = 'Invalid'
                Path          = $configurationPath
                Configuration = $null
                ErrorMessage  = 'The project configuration file is empty.'
            }
        }

        $configuration = ConvertFrom-ZprintProjectJson -JsonContent $jsonContent

        if ($null -eq $configuration -or
            $configuration -isnot [System.Collections.IDictionary]) {
            return [pscustomobject]@{
                Status        = 'Invalid'
                Path          = $configurationPath
                Configuration = $null
                ErrorMessage  = 'The project configuration root must be a JSON object.'
            }
        }

        return [pscustomobject]@{
            Status        = 'Loaded'
            Path          = $configurationPath
            Configuration = $configuration
            ErrorMessage  = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Status        = 'Invalid'
            Path          = $configurationPath
            Configuration = $null
            ErrorMessage  = $_.Exception.Message
        }
    }
}

function Test-ZprintProjectConfiguration {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Configuration
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $missingFields = [System.Collections.Generic.List[string]]::new()
    $invalidFields = [System.Collections.Generic.List[string]]::new()

    if ($null -eq $Configuration -or
        $Configuration -isnot [System.Collections.IDictionary]) {
        $errors.Add('The configuration root must be a JSON object.')

        return [pscustomobject]@{
            IsValid       = $false
            IsComplete    = $false
            Errors        = @($errors)
            MissingFields = @($missingFields)
            InvalidFields = @('root')
        }
    }

    if (-not $Configuration.Contains('project')) {
        $missingFields.Add('project')
    }
    elseif ($Configuration['project'] -isnot [System.Collections.IDictionary]) {
        $invalidFields.Add('project')
        $errors.Add("The 'project' value must be a JSON object.")
    }
    else {
        $requiredFields = @(
            'name',
            'product',
            'description',
            'version',
            'milestone',
            'orchestrator'
        )

        foreach ($fieldName in $requiredFields) {
            if (-not $Configuration['project'].Contains($fieldName)) {
                $missingFields.Add("project.$fieldName")
                continue
            }

            $fieldValue = $Configuration['project'][$fieldName]

            if ($fieldValue -isnot [string]) {
                $invalidFields.Add("project.$fieldName")
                $errors.Add("The 'project.$fieldName' value must be a string.")
            }
            elseif ([string]::IsNullOrWhiteSpace($fieldValue)) {
                $missingFields.Add("project.$fieldName")
            }
        }
    }

    foreach ($field in $missingFields) {
        $errors.Add("Required configuration field is missing or empty: $field")
    }

    [pscustomobject]@{
        IsValid       = ($invalidFields.Count -eq 0)
        IsComplete    = ($missingFields.Count -eq 0)
        Errors        = @($errors)
        MissingFields = @($missingFields)
        InvalidFields = @($invalidFields)
    }
}

function Get-ZprintConfigurationState {
    $readResult = Read-ZprintProjectConfiguration

    if ($readResult.Status -eq 'Missing') {
        return [pscustomobject]@{
            State          = 'Missing'
            Path           = $readResult.Path
            Exists         = $false
            Configuration  = $null
            Errors         = @()
            MissingFields  = @()
            InvalidFields  = @()
        }
    }

    if ($readResult.Status -ne 'Loaded') {
        return [pscustomobject]@{
            State          = 'Invalid'
            Path           = $readResult.Path
            Exists         = $true
            Configuration  = $null
            Errors         = @($readResult.ErrorMessage)
            MissingFields  = @()
            InvalidFields  = @('file')
        }
    }

    $validation = Test-ZprintProjectConfiguration `
        -Configuration $readResult.Configuration

    $state = if (-not $validation.IsValid) {
        'Invalid'
    }
    elseif (-not $validation.IsComplete) {
        'Incomplete'
    }
    else {
        'Valid'
    }

    [pscustomobject]@{
        State          = $state
        Path           = $readResult.Path
        Exists         = $true
        Configuration  = $readResult.Configuration
        Errors         = $validation.Errors
        MissingFields  = $validation.MissingFields
        InvalidFields  = $validation.InvalidFields
    }
}

# ==============================================================================
# 08. LOGGING FOUNDATION
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
# 09. COMMAND HANDLERS
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
# 10. COMMAND VALIDATION
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
# 11. MAIN EXECUTION AND ERROR HANDLING
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
