<#
.SYNOPSIS
    Verification script for windows-base Ansible role.

.DESCRIPTION
    Runs verification checks to confirm the windows-base role was applied correctly.
    Can verify individual components or all components at once.

.PARAMETER Component
    Component to verify: All, Choco, Security, Agents, CredSSP

.EXAMPLE
    .\verify.ps1 -Component All
    .\verify.ps1 -Component Choco
    .\verify.ps1 -Component Security
#>

param(
    [ValidateSet("All", "Choco", "Security", "Agents", "CredSSP")]
    [string]$Component = "All"
)

$ErrorActionPreference = "Continue"
$script:TestsPassed = 0
$script:TestsFailed = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )

    if ($Passed) {
        Write-Host "[PASS] " -ForegroundColor Green -NoNewline
        $script:TestsPassed++
    } else {
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
        $script:TestsFailed++
    }
    Write-Host $TestName
    if ($Details) {
        Write-Host "       $Details" -ForegroundColor Gray
    }
}

function Test-Chocolatey {
    Write-Host "`n=== Chocolatey Verification ===" -ForegroundColor Cyan

    # Check choco.exe exists
    $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
    Write-TestResult "Chocolatey executable found" ($null -ne $chocoPath) $chocoPath.Source

    # Check version
    if ($chocoPath) {
        $version = & choco -v 2>$null
        Write-TestResult "Chocolatey version retrieved" ($version -match '^\d+\.\d+') $version
    }

    # Check environment variables
    $chocoInstall = [Environment]::GetEnvironmentVariable("ChocolateyInstall", "Machine")
    Write-TestResult "ChocolateyInstall env var set" ($null -ne $chocoInstall) $chocoInstall

    $chocoTools = [Environment]::GetEnvironmentVariable("ChocolateyToolsLocation", "Machine")
    Write-TestResult "ChocolateyToolsLocation env var set" ($null -ne $chocoTools) $chocoTools

    # Check PATH
    $path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $chocoInPath = $path -like "*choco*"
    Write-TestResult "Chocolatey bin in PATH" $chocoInPath
}

function Test-Security {
    Write-Host "`n=== Security Verification ===" -ForegroundColor Cyan

    # Check local Administrators group
    try {
        $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        Write-TestResult "Administrators group accessible" $true "$($admins.Count) members"
    } catch {
        Write-TestResult "Administrators group accessible" $false $_.Exception.Message
    }

    # Check for test folders (if they exist)
    $testFolders = @(
        "C:\test\readonly",
        "C:\test\modify",
        "C:\test\jenkins"
    )

    foreach ($folder in $testFolders) {
        if (Test-Path $folder) {
            $acl = Get-Acl $folder -ErrorAction SilentlyContinue
            Write-TestResult "Folder exists: $folder" $true "$($acl.Access.Count) ACL entries"
        }
    }

    # Check SMB shares
    try {
        $shares = Get-SmbShare -ErrorAction Stop | Where-Object { $_.Name -notlike "*$" }
        Write-TestResult "SMB shares accessible" $true "$($shares.Count) user shares"
    } catch {
        Write-TestResult "SMB shares accessible" $false $_.Exception.Message
    }
}

function Test-Agents {
    Write-Host "`n=== Agent Verification ===" -ForegroundColor Cyan

    $agents = @(
        @{ Name = "Splunk"; ServicePattern = "Splunk*"; ProductPattern = "*Splunk*" },
        @{ Name = "Nessus"; ServicePattern = "Nessus*"; ProductPattern = "*Nessus*" },
        @{ Name = "Seeker"; ServicePattern = "Seeker*"; ProductPattern = "*Seeker*" }
    )

    foreach ($agent in $agents) {
        # Check if service exists
        $service = Get-Service -Name $agent.ServicePattern -ErrorAction SilentlyContinue
        if ($service) {
            Write-TestResult "$($agent.Name) service found" $true "$($service.Name) - $($service.Status)"
        } else {
            Write-TestResult "$($agent.Name) service found" $false "Not installed or service not found"
        }
    }

    # Check temp directory
    $tempDir = "C:\temp\agents"
    if (Test-Path $tempDir) {
        Write-TestResult "Agents temp directory exists" $true $tempDir
    }
}

function Test-CredSSP {
    Write-Host "`n=== CredSSP Verification ===" -ForegroundColor Cyan

    try {
        $credSSP = Get-WSManCredSSP -ErrorAction Stop
        Write-TestResult "CredSSP configuration retrieved" $true

        # Check server role
        $serverEnabled = $credSSP -match "server.*is configured to receive"
        Write-TestResult "CredSSP Server role enabled" $serverEnabled

        # Check client role
        $clientEnabled = $credSSP -match "client.*is configured to delegate"
        Write-TestResult "CredSSP Client role enabled" $clientEnabled

    } catch {
        Write-TestResult "CredSSP configuration retrieved" $false $_.Exception.Message
    }

    # Check WinRM service
    $winrm = Get-Service -Name WinRM -ErrorAction SilentlyContinue
    if ($winrm) {
        Write-TestResult "WinRM service status" ($winrm.Status -eq "Running") $winrm.Status
    }
}

function Show-Summary {
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Tests Passed: " -NoNewline
    Write-Host $script:TestsPassed -ForegroundColor Green
    Write-Host "Tests Failed: " -NoNewline
    Write-Host $script:TestsFailed -ForegroundColor $(if ($script:TestsFailed -gt 0) { "Red" } else { "Green" })

    $total = $script:TestsPassed + $script:TestsFailed
    if ($total -gt 0) {
        $percentage = [math]::Round(($script:TestsPassed / $total) * 100, 1)
        Write-Host "Success Rate: $percentage%"
    }
}

# Main execution
Write-Host "Windows Base Role Verification" -ForegroundColor Yellow
Write-Host "===============================" -ForegroundColor Yellow
Write-Host "Component: $Component"
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Computer: $env:COMPUTERNAME"

switch ($Component) {
    "All" {
        Test-Chocolatey
        Test-Security
        Test-Agents
        Test-CredSSP
    }
    "Choco" { Test-Chocolatey }
    "Security" { Test-Security }
    "Agents" { Test-Agents }
    "CredSSP" { Test-CredSSP }
}

Show-Summary

# Exit with appropriate code
if ($script:TestsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
