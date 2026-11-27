#requires -Version 7.0
<#
.SYNOPSIS
    ZPRINT project foundation and command-line orchestrator.

.DESCRIPTION
    Provides the initial command-line interface for the ZPRINT project.
    This foundation intentionally avoids application frameworks and external
    module dependencies.

.VERSION
    0.1.0

.MILESTONE
    Project Foundation
#>

[CmdletBinding(DefaultParameterSetName = 'Help')]
param (
    [Parameter(
        ParameterSetName = 'Help',
        HelpMessage = 'Display command-line help.'
    )]
    [switch]$Help,

    [Parameter(
        ParameterSetName = 'Version',
        HelpMessage = 'Display project version information.'
    )]
    [switch]$Version,

    [Parameter(
        ParameterSetName = 'Status',
        HelpMessage = 'Display the current project status.'
    )]
    [switch]$Status,

    [Parameter(
        ParameterSetName = 'Doctor',
        HelpMessage = 'Run basic environment diagnostics.'
    )]
    [switch]$Doctor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# PROJECT METADATA
# ---------------------------------------------------------------------------

$Project = [ordered]@{
    Name        = 'ZPRINT'
    ProductName = 'ZPRINT STUDIO'
    Description = 'Digital Design & Production Platform'
    Tagline     = 'DESIGN. VISUALIZE. PRODUCE.'
    Version     = '0.1.0'
    Milestone   = 'Project Foundation'
    ScriptName  = 'zprint.ps1'
}

# Resolve the project root from the location of this script.
$ProjectRoot = $PSScriptRoot

# ---------------------------------------------------------------------------
# OUTPUT HELPERS
# ---------------------------------------------------------------------------

function Write-Header {
    param (
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ''
    Write-Host $Project.ProductName -ForegroundColor Cyan
    Write-Host $Title
    Write-Host ('-' * 58) -ForegroundColor DarkGray
}

function Write-Result {
    param (
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$Value,

        [ValidateSet('Default', 'Success', 'Warning', 'Error')]
        [string]$State = 'Default'
    )

    $color = switch ($State) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        default   { 'Gray' }
    }

    Write-Host ('{0,-22} {1}' -f "${Label}:", $Value) -ForegroundColor $color
}

# ---------------------------------------------------------------------------
# COMMAND HANDLERS
# ---------------------------------------------------------------------------

function Show-Help {
    Write-Header -Title 'Command-line interface'

    Write-Host ''
    Write-Host 'USAGE' -ForegroundColor White
    Write-Host '  pwsh -File ./zprint.ps1 -<Command>'
    Write-Host '  pwsh -File ./zprint.ps1'
    Write-Host ''

    Write-Host 'COMMANDS' -ForegroundColor White
    Write-Host '  -Help       Display this help information.'
    Write-Host '  -Version    Display project version information.'
    Write-Host '  -Status     Display the current project status.'
    Write-Host '  -Doctor     Run basic environment diagnostics.'
    Write-Host ''

    Write-Host 'EXAMPLES' -ForegroundColor White
    Write-Host '  pwsh -File ./zprint.ps1 -Help'
    Write-Host '  pwsh -File ./zprint.ps1 -Version'
    Write-Host '  pwsh -File ./zprint.ps1 -Status'
    Write-Host '  pwsh -File ./zprint.ps1 -Doctor'
    Write-Host ''

    Write-Host 'NOTES' -ForegroundColor White
    Write-Host '  Select exactly one command.'
    Write-Host '  Running without a command displays help.'
    Write-Host '  Git operations are intentionally independent.'
    Write-Host ''
}

function Show-Version {
    Write-Header -Title 'Version information'

    Write-Result -Label 'Project' -Value $Project.Name
    Write-Result -Label 'Product' -Value $Project.ProductName
    Write-Result -Label 'Version' -Value $Project.Version -State Success
    Write-Result -Label 'Milestone' -Value $Project.Milestone
    Write-Result -Label 'Script' -Value $Project.ScriptName
    Write-Host ''
}

function Show-Status {
    Write-Header -Title 'Project status'

    $scriptPath = Join-Path -Path $ProjectRoot -ChildPath $Project.ScriptName
    $scriptExists = Test-Path -LiteralPath $scriptPath -PathType Leaf

    Write-Result -Label 'Project' -Value $Project.Name
    Write-Result -Label 'Version' -Value $Project.Version
    Write-Result -Label 'Milestone' -Value $Project.Milestone
    Write-Result -Label 'Project root' -Value $ProjectRoot
    Write-Result -Label 'Orchestrator' -Value $Project.ScriptName
    Write-Result -Label 'Script present' -Value ([string]$scriptExists) -State $(if ($scriptExists) { 'Success' } else { 'Error' })

    Write-Host ''
    Write-Host 'This command reports the local foundation only.'
    Write-Host 'It does not inspect Git history or modify project files.'
    Write-Host ''
}

function Invoke-Doctor {
    Write-Header -Title 'Environment diagnostics'

    $powerShellVersion = $PSVersionTable.PSVersion.ToString()
    $platform = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    # Resolve the executable path as a plain string. On some PowerShell
    # platforms, passing the command metadata object or one of its properties
    # directly can cause parameter-conversion errors.
    $gitCommand = Get-Command -Name git -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1

    Write-Result -Label 'PowerShell' -Value ([string]$powerShellVersion) -State Success
    Write-Result -Label 'Platform' -Value ([string]$platform)

    if ($null -ne $gitCommand) {
        $gitPath = [string]$gitCommand.Definition
        Write-Result -Label 'Git executable' -Value $gitPath -State Success
    }
    else {
        Write-Result -Label 'Git executable' -Value 'Not found (optional)' -State Warning
    }

    Write-Result -Label 'Project root' -Value $ProjectRoot
    Write-Result -Label 'External modules' -Value 'None required' -State Success

    Write-Host ''
    Write-Host 'Diagnostics do not execute Git commands or install dependencies.'
    Write-Host ''
}

# ---------------------------------------------------------------------------
# COMMAND ROUTER
# ---------------------------------------------------------------------------

try {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'ZPRINT requires PowerShell 7.0 or later.'
    }

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
            Invoke-Doctor
        }
        default {
            throw "Unsupported command parameter set: $($PSCmdlet.ParameterSetName)"
        }
    }

    exit 0
}
catch {
    [Console]::Error.WriteLine("ZPRINT ERROR: $($_.Exception.Message)")
    exit 1
}
