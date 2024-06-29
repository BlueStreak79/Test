# Function to check if running as admin
function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Restarting script with administrative privileges..."
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

# Main script
Ensure-Admin
Ensure-ExecutionPolicy

# Define download URLs and paths
$tempDir = [System.IO.Path]::GetTempPath()
$script1Path = Join-Path -Path $tempDir -ChildPath "Cam-Audio.ps1"
$exe1Path = Join-Path -Path $tempDir -ChildPath "AquaKeyTest.exe"
$exe2Path = Join-Path -Path $tempDir -ChildPath "BatteryInfoView.exe"
$script2Path = Join-Path -Path $tempDir -ChildPath "oem.ps1"

# Start background jobs for downloading and executing files
$jobs = @()

# Define download functions
function DownloadAndExecute {
    param (
        [string]$url,
        [string]$output
    )
    
    # Download file
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
    
    # Execute file
    Start-Process $output -Wait -NoNewWindow
}

# Start jobs for each file download and execution
$jobs += Start-Job -ScriptBlock { DownloadAndExecute -url "https://github.com/BlueStreak79/Test/raw/main/Cam-Audio.ps1" -output $using:script1Path }
$jobs += Start-Job -ScriptBlock { DownloadAndExecute -url "https://github.com/BlueStreak79/Test/raw/main/AquaKeyTest.exe" -output $using:exe1Path }
$jobs += Start-Job -ScriptBlock { DownloadAndExecute -url "https://github.com/BlueStreak79/Test/raw/main/BatteryInfoView.exe" -output $using:exe2Path }
$jobs += Start-Job -ScriptBlock { DownloadAndExecute -url "https://github.com/BlueStreak79/Test/raw/main/oem.ps1" -output $using:script2Path }

# Wait for all jobs to complete
$jobs | Wait-Job | Receive-Job

# Clean up jobs
$jobs | Remove-Job

Write-Host "Script completed."
