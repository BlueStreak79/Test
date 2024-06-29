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

# Function to download a file from a given URL with error handling and retries
function Download-File {
    param (
        [string]$url,
        [string]$output,
        [int]$retries = 3
    )
    $attempt = 0
    while ($attempt -lt $retries) {
        try {
            Write-Host "Attempting to download $url to $output (Attempt $($attempt + 1))"
            Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing -ErrorAction Stop
            Write-Host "Download successful: $url"
            return $true
        } catch {
            Write-Host "Failed to download $url: $($_.Exception.Message)"
            $attempt++
            if ($attempt -eq $retries) {
                return $false
            }
            Start-Sleep -Seconds 5
        }
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

# Download files
$downloadSuccess = $true
$downloadSuccess = $downloadSuccess -and (Download-File -url "https://github.com/BlueStreak79/Test/raw/main/Cam-Audio.ps1" -output $script1Path)
$downloadSuccess = $downloadSuccess -and (Download-File -url "https://github.com/BlueStreak79/Test/raw/main/AquaKeyTest.exe" -output $exe1Path)
$downloadSuccess = $downloadSuccess -and (Download-File -url "https://github.com/BlueStreak79/Test/raw/main/BatteryInfoView.exe" -output $exe2Path)
$downloadSuccess = $downloadSuccess -and (Download-File -url "https://github.com/BlueStreak79/Test/raw/main/oem.ps1" -output $script2Path)

if (-not $downloadSuccess) {
    Write-Host "One or more files failed to download."
    Exit 1
}

# Execute scripts and executables
Write-Host "Executing scripts and executables..."
try {
    Start-Process powershell.exe -ArgumentList "-File `"$script1Path`"" -Wait -NoNewWindow
    Start-Process $exe1Path -Wait
    Start-Process $exe2Path -Wait
    Start-Process powershell.exe -ArgumentList "-File `"$script2Path`"" -Wait -NoNewWindow
    Write-Host "Execution completed successfully."
} catch {
    Write-Host "Error executing scripts and executables: $_"
}

Write-Host "Script completed."
