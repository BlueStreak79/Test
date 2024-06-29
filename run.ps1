# Function to check if running as admin
function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Log-Message "Restarting script with administrative privileges..."
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
            Log-Message "Attempting to download $url to $output (Attempt $($attempt + 1))"
            Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing -ErrorAction Stop
            Log-Message "Download successful: $url"
            return
        } catch {
            $errorMessage = $_.Exception.Message
            Show-ErrorPopup "Failed to download and execute $($url):`n$($errorMessage)"
            $attempt++
            if ($attempt -eq $retries) {
                throw "Failed to download $url after $retries attempts."
            }
            Start-Sleep -Seconds 5
        }
    }
}

# Function to replace a file in a specified directory
function Replace-File {
    param (
        [string]$source,
        [string]$destination
    )
    Log-Message "Replacing file in $destination with $source"
    Copy-Item -Path $source -Destination $destination -Force
}

# Logging function
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Output $message
}

# Function to display error in a popup
function Show-ErrorPopup {
    param (
        [string]$message
    )
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($message, "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
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
$logFile = Join-Path -Path $tempDir -ChildPath "script_log.txt"

# Download files
Download-File -url "https://github.com/BlueStreak79/Test/raw/main/Cam-Audio.ps1" -output $script1Path
Download-File -url "https://github.com/BlueStreak79/Test/raw/main/AquaKeyTest.exe" -output $exe1Path
Download-File -url "https://github.com/BlueStreak79/Test/raw/main/BatteryInfoView.exe" -output $exe2Path
Download-File -url "https://github.com/BlueStreak79/Test/raw/main/oem.ps1" -output $script2Path

# Execute scripts and executables
Log-Message "Executing scripts and executables..."
try {
    Start-Process powershell.exe -ArgumentList "-File `"$script1Path`"" -Wait -NoNewWindow
    Start-Process $exe1Path -Wait
    Start-Process $exe2Path -Wait
    Start-Process powershell.exe -ArgumentList "-File `"$script2Path`"" -Wait -NoNewWindow
    Log-Message "Execution completed successfully."
} catch {
    Log-Message "Error executing scripts and executables: $_"
}

# Display log location
Log-Message "Script completed. View log at: $logFile"
