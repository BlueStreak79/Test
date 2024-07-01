# Function to check if running as admin
function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process powershell.exe "-File $PSCommandPath" -Verb RunAs
        Exit
    }
}

# Function to ensure execution policy allows script execution
function Ensure-ExecutionPolicy {
    $currentPolicy = Get-ExecutionPolicy
    if ($currentPolicy -ne 'Unrestricted') {
        Set-ExecutionPolicy Unrestricted -Scope Process -Force
    }
}

# Function to download a file from a given URL
function Download-File {
    param (
        [string]$url,
        [string]$output
    )
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Function to download and execute a file
function DownloadAndExecute {
    param (
        [string]$url,
        [string]$output
    )
    
    if (Download-File -url $url -output $output) {
        if ($output -like "*.ps1") {
            try {
                . $output
            } catch {
                Write-Error "Failed to execute script $output. Error: $_"
            }
        } elseif ($output -like "*.exe") {
            try {
                Start-Process $output -NoNewWindow -ErrorAction Stop
            } catch {
                Write-Error "Failed to execute executable $output. Error: $_"
            }
        }
    } else {
        Write-Error "Failed to download file from $url"
    }
}

# Main script
Ensure-Admin
Ensure-ExecutionPolicy

# Define download URLs and paths
$tempDir = [System.IO.Path]::GetTempPath()
$files = @{
    "https://github.com/BlueStreak79/Test/raw/main/oem.ps1"        = Join-Path -Path $tempDir -ChildPath "oem.ps1"
    "https://github.com/BlueStreak79/Test/raw/main/Cam-Audio.ps1"  = Join-Path -Path $tempDir -ChildPath "Cam-Audio.ps1"
    "https://github.com/BlueStreak79/Test/raw/main/BatteryInfoView.exe" = Join-Path -Path $tempDir -ChildPath "BatteryInfoView.exe"
    "https://github.com/BlueStreak79/Test/raw/main/AquaKeyTest.exe" = Join-Path -Path $tempDir -ChildPath "AquaKeyTest.exe"
}

# Start background jobs for downloading and executing files
$jobs = @()
foreach ($url in $files.Keys) {
    $output = $files[$url]
    $jobs += Start-Job -ScriptBlock { param($url, $output) DownloadAndExecute -url $url -output $output } -ArgumentList $url, $output
}

# Wait for all jobs to complete
$jobs | Wait-Job | Receive-Job

# Clean up jobs
$jobs | Remove-Job

# Clean up downloaded files
$files.Values | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item $_ -Force
    }
}
