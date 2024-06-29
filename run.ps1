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

# Download files
Invoke-WebRequest -Uri "https://github.com/BlueStreak79/Test/raw/main/Cam-Audio.ps1" -OutFile $script1Path -UseBasicParsing
Invoke-WebRequest -Uri "https://github.com/BlueStreak79/Test/raw/main/AquaKeyTest.exe" -OutFile $exe1Path -UseBasicParsing
Invoke-WebRequest -Uri "https://github.com/BlueStreak79/Test/raw/main/BatteryInfoView.exe" -OutFile $exe2Path -UseBasicParsing
Invoke-WebRequest -Uri "https://github.com/BlueStreak79/Test/raw/main/oem.ps1" -OutFile $script2Path -UseBasicParsing

# Execute scripts and executables
Start-Process powershell.exe -ArgumentList "-File `"$script1Path`"" -Wait -NoNewWindow
Start-Process $exe1Path -Wait
Start-Process $exe2Path -Wait
Start-Process powershell.exe -ArgumentList "-File `"$script2Path`"" -Wait -NoNewWindow

Write-Host "Script completed."
