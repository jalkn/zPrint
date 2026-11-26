#requires -Version 7.0
<#
.SYNOPSIS
    ZPRINT single-file project generator.

.DESCRIPTION
    Establishes the ZPRINT project foundation and provides command routing,
    configuration validation, diagnostics, and execution logging.

.NOTES
    Generator: zprint.ps1
    Version: 0.1.0
    Milestone: 4.1 - Generator Foundation
    Runtime: PowerShell 7+
#>

[CmdletBinding()]
param(
    [switch]$Generate,
    [switch]$GeneratePortal,
    [switch]$GenerateAI,
    [switch]$GenerateCore,
    [switch]$GenerateBackend,
    [switch]$GenerateDatabase,
    [switch]$GenerateOperations,
    [switch]$GenerateBrand,
    [switch]$GenerateCatalog,

    [switch]$Initialize,
    [switch]$Validate,

    [switch]$Build,
    [switch]$BuildPortal,
    [switch]$BuildAI,
    [switch]$BuildCore,
    [switch]$BuildBackend,
    [switch]$BuildDatabase,
    [switch]$BuildOperations,
    [switch]$BuildBrand,
    [switch]$BuildCatalog,

    [switch]$Preview,
    [switch]$PreviewBrand,

    [switch]$Status,
    [switch]$Doctor,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 01. CONSTANTS
# ---------------------------------------------------------------------------

$script:GeneratorName    = 'ZPRINT'
$script:GeneratorVersion = '0.1.0'
$script:Milestone        = '4.1'
$script:ExitCode         = 0
$script:CurrentCommand   = 'None'
$script:ProjectRoot      = [System.IO.Path]::GetFullPath($PSScriptRoot)
$script:ConfigPaths      = [ordered]@{
    Project = Join-Path $script:ProjectRoot 'config/project.json'
    Build   = Join-Path $script:ProjectRoot 'config/build.json'
    Brand   = Join-Path $script:ProjectRoot 'config/brand.json'
}
$script:LoadedConfig     = @{}
$script:LogPath          = Join-Path $script:ProjectRoot 'build/logs/zprint.log'

# ---------------------------------------------------------------------------
# 02. COMMAND REGISTRY
# ---------------------------------------------------------------------------

$script:CommandNames = @(
    'Generate', 'GeneratePortal', 'GenerateAI', 'GenerateCore',
    'GenerateBackend', 'GenerateDatabase', 'GenerateOperations',
    'GenerateBrand', 'GenerateCatalog',
    'Initialize', 'Validate',
    'Build', 'BuildPortal', 'BuildAI', 'BuildCore', 'BuildBackend',
    'BuildDatabase', 'BuildOperations', 'BuildBrand', 'BuildCatalog',
    'Preview', 'PreviewBrand',
    'Status', 'Doctor', 'Help'
)

$script:ImplementedCommands = @('Initialize', 'Validate', 'Status', 'Doctor', 'Help')

# ---------------------------------------------------------------------------
# 03. LOGGING
# ---------------------------------------------------------------------------

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $logDirectory = Split-Path -Parent $script:LogPath
    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }

    $safeMessage = $Message -replace '[\r\n]+', ' '
    $entry = '{0} | {1} | v{2} | {3} | {4}' -f `
        (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'),
        $Level,
        $script:GeneratorVersion,
        $script:CurrentCommand,
        $safeMessage

    Add-Content -LiteralPath $script:LogPath -Value $entry -Encoding utf8
}

# ---------------------------------------------------------------------------
# 04. CONFIGURATION
# ---------------------------------------------------------------------------

function Get-DefaultConfigurations {
    return [ordered]@{
        Project = [ordered]@{
            name        = 'ZPRINT'
            product     = 'ZPRINT - AI Printing Portal'
            version     = '0.1.0'
            description = 'AI-powered conversational portal for printing services.'
            generator   = [ordered]@{
                name      = $script:GeneratorName
                version   = $script:GeneratorVersion
                milestone = $script:Milestone
            }
            paths       = [ordered]@{
                portal   = 'portal'
                backend  = 'backend'
                database = 'database'
                brand    = 'brand'
                build    = 'build'
            }
        }
        Build = [ordered]@{
            version       = '1.0'
            environment   = 'development'
            deployment    = [ordered]@{
                enabled = $false
            }
            preview       = [ordered]@{
                host = '127.0.0.1'
                port = 8000
            }
            generation    = [ordered]@{
                manifest = 'build/generation-manifest.json'
                conflict = 'manual'
                overwriteRequiresExplicitAuthorization = $true
            }
        }
        Brand = [ordered]@{
            name       = 'ZPRINT STUDIO'
            positioning = 'DIGITAL DESIGN & PRODUCTION PLATFORM'
            tagline    = 'DESIGN. VISUALIZE. PRODUCE.'
            colors     = [ordered]@{
                background = '#000000'
                foreground = '#FFFFFF'
                cyan       = '#00F0FF'
                blue       = '#0066FF'
            }
            logo       = [ordered]@{
                source = 'brand/assets/zPrint.svg'
                geometry = 'three proportional parallelograms'
                masterUnit = 'middle'
                preserveOriginal = $true
            }
        }
    }
}

function Get-ConfigurationState {
    $missing = @()
    $invalid = @()
    $parsed = @{}

    foreach ($name in @('Project', 'Build', 'Brand')) {
        $path = $script:ConfigPaths[$name]

        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $missing += $path
            continue
        }

        try {
            $raw = Get-Content -LiteralPath $path -Raw -Encoding utf8
            if ([string]::IsNullOrWhiteSpace($raw)) {
                throw 'Configuration file is empty.'
            }

            $data = ConvertFrom-Json -InputObject $raw -AsHashtable
            if ($null -eq $data -or $data -isnot [System.Collections.IDictionary]) {
                throw 'Configuration root must be a JSON object.'
            }

            $parsed[$name] = $data
        }
        catch {
            $invalid += ('{0}: {1}' -f $path, $_.Exception.Message)
        }
    }

    $state = if ($invalid.Count -gt 0) {
        'Invalid'
    }
    elseif ($missing.Count -gt 0) {
        'Uninitialized'
    }
    else {
        'Valid'
    }

    return [pscustomobject]@{
        State   = $state
        Missing = $missing
        Invalid = $invalid
        Config  = $parsed
    }
}

function Import-ProjectConfiguration {
    $state = Get-ConfigurationState
    if ($state.State -ne 'Valid') {
        if ($state.State -eq 'Invalid') {
            throw [System.IO.InvalidDataException]::new(
                ('Invalid configuration: ' + ($state.Invalid -join '; '))
            )
        }

        throw [System.IO.FileNotFoundException]::new(
            ('Missing required configuration: ' + ($state.Missing -join '; '))
        )
    }

    $script:LoadedConfig = $state.Config
    return $state
}

# ---------------------------------------------------------------------------
# 05. PROJECT INITIALIZATION
# ---------------------------------------------------------------------------

function Initialize-Project {
    $defaults = Get-DefaultConfigurations

    $directories = @(
        'config',
        'build/logs',
        'brand/assets'
    )

    foreach ($relativePath in $directories) {
        $target = Join-Path $script:ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $target -PathType Container)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            Write-Log -Level INFO -Message "Created directory: $relativePath"
        }
    }

    foreach ($name in @('Project', 'Build', 'Brand')) {
        $target = $script:ConfigPaths[$name]

        if (Test-Path -LiteralPath $target -PathType Leaf) {
            Write-Log -Level INFO -Message "Preserved existing configuration: $target"
            continue
        }

        $json = $defaults[$name] | ConvertTo-Json -Depth 12
        Set-Content -LiteralPath $target -Value $json -Encoding utf8
        Write-Log -Level INFO -Message "Created configuration: $target"
    }

    # Preserve the supplied master vector. Copy it only when the user places
    # zPrint.svg beside this generator and the destination does not exist.
    $sourceSvg = Join-Path $script:ProjectRoot 'zPrint.svg'
    $destinationSvg = Join-Path $script:ProjectRoot 'brand/assets/zPrint.svg'
    if ((Test-Path -LiteralPath $sourceSvg -PathType Leaf) -and
        -not (Test-Path -LiteralPath $destinationSvg -PathType Leaf)) {
        Copy-Item -LiteralPath $sourceSvg -Destination $destinationSvg
        Write-Log -Level INFO -Message 'Copied the supplied master SVG into brand/assets without modification.'
    }
    elseif (Test-Path -LiteralPath $destinationSvg -PathType Leaf) {
        Write-Log -Level INFO -Message 'Preserved existing brand/assets/zPrint.svg.'
    }
    else {
        Write-Log -Level WARN -Message 'Master SVG not found beside the generator; brand asset copy was skipped.'
    }

    $configuration = Get-ConfigurationState
    if ($configuration.State -ne 'Valid') {
        throw [System.IO.InvalidDataException]::new(
            'Initialization finished, but the resulting configuration is not valid.'
        )
    }

    Write-Log -Level INFO -Message 'Project foundation initialized successfully.'
    Write-Host 'ZPRINT project foundation is initialized.' -ForegroundColor Green
    Write-Host 'Existing configuration files were preserved.'
    Write-Host 'Framework generation remains a separate operation.'
}

# ---------------------------------------------------------------------------
# 06. COMMANDS
# ---------------------------------------------------------------------------

function Show-Help {
    @'
ZPRINT - AI Printing Portal
Single-file generator foundation
Version 0.1.0 | Milestone 4.1

USAGE
  pwsh -File ./zprint.ps1 -<Command>

IMPLEMENTED FOUNDATION COMMANDS
  -Initialize    Create the initial project directories and configuration.
  -Validate      Validate required configuration files.
  -Status        Show project and configuration status.
  -Doctor        Inspect runtime and local environment.
  -Help          Display this help.

RECOGNIZED, RESERVED COMMANDS
  Generation: -Generate, -GeneratePortal, -GenerateAI, -GenerateCore,
              -GenerateBackend, -GenerateDatabase, -GenerateOperations,
              -GenerateBrand, -GenerateCatalog
  Build:      -Build, -BuildPortal, -BuildAI, -BuildCore, -BuildBackend,
              -BuildDatabase, -BuildOperations, -BuildBrand, -BuildCatalog
  Preview:    -Preview, -PreviewBrand

Reserved commands return NOT-IMPLEMENTED until their milestones are delivered.
Exactly one primary command is allowed per invocation.
There is no implicit default operation.

EXAMPLES
  pwsh -File ./zprint.ps1 -Help
  pwsh -File ./zprint.ps1 -Initialize
  pwsh -File ./zprint.ps1 -Status
  pwsh -File ./zprint.ps1 -Validate
  pwsh -File ./zprint.ps1 -Doctor

EXIT CODES
  0  Success
  1  Validation or build failure
  2  Invalid command or arguments
  3  Missing or invalid configuration
  4  Environment or dependency failure
  5  File conflict
'@ | Write-Host
}

function Show-Status {
    $configuration = Get-ConfigurationState

    Write-Host 'ZPRINT STATUS'
    Write-Host ('Project root: {0}' -f $script:ProjectRoot)
    Write-Host ('Generator:    {0} v{1}' -f $script:GeneratorName, $script:GeneratorVersion)
    Write-Host ('PowerShell:   {0}' -f $PSVersionTable.PSVersion)
    Write-Host ('Initialized:  {0}' -f ($configuration.State -eq 'Valid'))
    Write-Host ('Configuration: {0}' -f $configuration.State)

    if ($configuration.Missing.Count -gt 0) {
        Write-Host 'Missing configuration:'
        $configuration.Missing | ForEach-Object { Write-Host "  - $_" }
    }

    if ($configuration.Invalid.Count -gt 0) {
        Write-Host 'Invalid configuration:'
        $configuration.Invalid | ForEach-Object { Write-Host "  - $_" }
    }

    Write-Log -Level INFO -Message ("Status requested; configuration state: {0}" -f $configuration.State)
}

function Test-ProjectConfiguration {
    $configuration = Get-ConfigurationState

    if ($configuration.State -eq 'Uninitialized') {
        Write-Log -Level WARN -Message 'Validation failed: project is not initialized.'
        Write-Host 'Validation failed: required configuration is missing.' -ForegroundColor Yellow
        $configuration.Missing | ForEach-Object { Write-Host "  - $_" }
        $script:ExitCode = 3
        return
    }

    if ($configuration.State -eq 'Invalid') {
        Write-Log -Level ERROR -Message ("Validation failed: {0}" -f ($configuration.Invalid -join '; '))
        Write-Host 'Validation failed: invalid configuration.' -ForegroundColor Red
        $configuration.Invalid | ForEach-Object { Write-Host "  - $_" }
        $script:ExitCode = 3
        return
    }

    $script:LoadedConfig = $configuration.Config
    Write-Log -Level INFO -Message 'Configuration validation passed.'
    Write-Host 'Configuration validation passed.' -ForegroundColor Green
}

function Invoke-Doctor {
    $configuration = Get-ConfigurationState
    $pythonCommand = Get-Command 'python3' -ErrorAction SilentlyContinue
    if (-not $pythonCommand) {
        $pythonCommand = Get-Command 'python' -ErrorAction SilentlyContinue
    }

    $checks = @(
        [pscustomobject]@{ Name = 'PowerShell version'; Result = $PSVersionTable.PSVersion.ToString(); Passed = ($PSVersionTable.PSVersion.Major -ge 7) }
        [pscustomobject]@{ Name = 'Operating system'; Result = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription; Passed = $true }
        [pscustomobject]@{ Name = 'Script location'; Result = $script:ProjectRoot; Passed = (Test-Path -LiteralPath $script:ProjectRoot -PathType Container) }
        [pscustomobject]@{ Name = 'Project initialization'; Result = $configuration.State; Passed = ($configuration.State -eq 'Valid') }
        [pscustomobject]@{ Name = 'Python availability'; Result = $(if ($pythonCommand) { $pythonCommand.Source } else { 'Not found' }); Passed = [bool]$pythonCommand }
    )

    Write-Host 'ZPRINT ENVIRONMENT DIAGNOSTICS'
    foreach ($check in $checks) {
        $status = if ($check.Passed) { 'PASS' } else { 'WARN' }
        Write-Host ('[{0}] {1}: {2}' -f $status, $check.Name, $check.Result)
    }

    $permissionPath = Join-Path $script:ProjectRoot '.'
    $permissionCheck = $false
    try {
        $probe = Join-Path $permissionPath ('.zprint-write-test-' + [guid]::NewGuid().ToString('N'))
        [System.IO.File]::WriteAllText($probe, 'test')
        Remove-Item -LiteralPath $probe -Force
        $permissionCheck = $true
    }
    catch {
        $permissionCheck = $false
    }

    $permissionStatus = if ($permissionCheck) { 'PASS' } else { 'WARN' }
    Write-Host ('[{0}] Project directory write permission: {1}' -f $permissionStatus, $permissionCheck)

    if (-not $checks[0].Passed) {
        $script:ExitCode = 4
    }
    elseif (-not $permissionCheck) {
        $script:ExitCode = 4
    }

    Write-Log -Level INFO -Message ("Doctor completed; configuration state: {0}; write access: {1}" -f $configuration.State, $permissionCheck)
}

# ---------------------------------------------------------------------------
# 07. COMMAND ROUTER
# ---------------------------------------------------------------------------

$selectedCommands = @()
foreach ($commandName in $script:CommandNames) {
    if ((Get-Variable -Name $commandName -ValueOnly -ErrorAction SilentlyContinue) -eq $true) {
        $selectedCommands += $commandName
    }
}

if ($selectedCommands.Count -eq 0) {
    Write-Host 'Error: specify exactly one primary command. Use -Help for usage.' -ForegroundColor Red
    $script:ExitCode = 2
}
elseif ($selectedCommands.Count -gt 1) {
    Write-Host ('Error: only one primary command is allowed. Received: {0}' -f ($selectedCommands -join ', ')) -ForegroundColor Red
    $script:ExitCode = 2
}
else {
    $script:CurrentCommand = $selectedCommands[0]

    try {
        switch ($script:CurrentCommand) {
            'Help' {
                Show-Help
            }
            'Initialize' {
                Initialize-Project
            }
            'Status' {
                Show-Status
            }
            'Validate' {
                Test-ProjectConfiguration
            }
            'Doctor' {
                Invoke-Doctor
            }
            default {
                $message = "Command '$($script:CurrentCommand)' is recognized but not implemented in Milestone $($script:Milestone)."
                Write-Log -Level WARN -Message $message
                Write-Host "NOT-IMPLEMENTED: $message" -ForegroundColor Yellow
                $script:ExitCode = 1
            }
        }
    }
    catch [System.IO.FileNotFoundException] {
        Write-Log -Level ERROR -Message $_.Exception.Message
        Write-Error $_.Exception.Message -ErrorAction Continue
        $script:ExitCode = 3
    }
    catch [System.IO.InvalidDataException] {
        Write-Log -Level ERROR -Message $_.Exception.Message
        Write-Error $_.Exception.Message -ErrorAction Continue
        $script:ExitCode = 3
    }
    catch [System.UnauthorizedAccessException] {
        Write-Log -Level ERROR -Message $_.Exception.Message
        Write-Error $_.Exception.Message -ErrorAction Continue
        $script:ExitCode = 5
    }
    catch {
        try {
            Write-Log -Level ERROR -Message $_.Exception.Message
        }
        catch {
            # Preserve the original exception if logging itself is unavailable.
        }

        Write-Error $_.Exception.Message -ErrorAction Continue
        $script:ExitCode = 1
    }
    finally {
        if ($script:CurrentCommand -ne 'None') {
            try {
                Write-Log -Level INFO -Message ("Execution completed with exit code {0}." -f $script:ExitCode)
            }
            catch {
                Write-Warning ("Unable to write execution log: {0}" -f $_.Exception.Message)
            }
        }
    }
}

exit $script:ExitCode
