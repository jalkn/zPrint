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
#   Milestone: 01 — Execution Foundation
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
    - Progressive implementation.
    - Idempotent operations.
    - Explicit file protection and overwrite policies.
    - Centralized validation and error handling.
    - Controlled platform generation.

    PLATFORM RESPONSIBILITIES
    - Brand and Design System.
    - Product Catalog and Pricing.
    - Studio and Customer Portal.
    - Backend and Database.
    - AI Agent Integration.
    - Production and Operations.
    - Documentation and Diagnostics.

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
    Milestone:     Execution Foundation
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
# 03. PROJECT METADATA
# ============================================================================== 

$script:ZprintVersion = '0.1.0'
$script:ZprintMilestone = '01 — Execution Foundation'

# ==============================================================================
# 04. COMMAND HANDLERS
# ============================================================================== 

function Show-ZprintHelp {
    $helpText = @'
ZPRINT STUDIO
DIGITAL DESIGN & PRODUCTION PLATFORM
DESIGN. VISUALIZE. PRODUCE.

SINGLE-FILE PLATFORM GENERATOR
Version 0.1.0 | Milestone 01 — Execution Foundation

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
    Write-Host 'ZPRINT STUDIO'
    Write-Host "Version:   $script:ZprintVersion"
    Write-Host "Milestone: $script:ZprintMilestone"
}

# ==============================================================================
# 05. COMMAND VALIDATION
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

    if ($UnexpectedArguments.Count -gt 0) {
        return [pscustomobject]@{
            IsValid      = $false
            Command      = $null
            ErrorMessage = "Unexpected positional argument(s): $($UnexpectedArguments -join ', ')"
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
# 06. MAIN EXECUTION
# ============================================================================== 

$commandState = Get-ZprintCommandState `
    -BoundParameters $PSBoundParameters `
    -UnexpectedArguments $RemainingArguments

if (-not $commandState.IsValid) {
    Write-Host "ERROR: $($commandState.ErrorMessage)" -ForegroundColor Red
    exit 2
}

switch ($commandState.Command) {
    'Help' {
        Show-ZprintHelp
        exit 0
    }

    'Version' {
        Show-ZprintVersion
        exit 0
    }
}
