# Function to check if running as admin
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to prompt elevation
function Request-Elevation {
    if (-not (Test-IsAdmin)) {
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

# Function to check if Camera app exists
function Test-CameraAppExists {
    $cameraApp = Get-AppxPackage -Name Microsoft.WindowsCamera
    return $cameraApp -ne $null
}

# Function to open camera
function Test-Camera {
    if (Test-CameraAppExists) {
        try {
            Write-Output "Opening Camera for testing..."
            Start-Process -FilePath "microsoft.windows.camera:"
        } catch {
            Write-Error "Failed to open Camera app. Please ensure the Camera app is installed and accessible."
        }
    } else {
        Write-Error "Camera app is not installed or not available on this system."
    }
}

# Function to open sound settings
function Test-Sound {
    try {
        Write-Output "Opening Sound settings for testing..."
        Start-Process -FilePath "ms-settings:sound"
    } catch {
        Write-Error "Failed to open Sound settings. Please ensure your Windows settings are accessible."
    }
}

# Function to log events
function Log-Event {
    param(
        [string]$message,
        [string]$logFile
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-content -Path $logFile -Value $logEntry
}

# Main script execution
Request-Elevation

# Parameters handling
if ($args -contains "-Camera") {
    Test-Camera
}

if ($args -contains "-Sound") {
    Start-Sleep -Seconds 5  # Wait for 5 seconds before opening sound settings
    Test-Sound
}

# Interactive mode
$interactive = $true
if ($args -contains "-NonInteractive") {
    $interactive = $false
}

if ($interactive) {
    Write-Output "Camera and Sound testing initiated. Please follow the on-screen instructions."

    # Logging events
    $logFile = "C:\Logs\CameraSoundTest.log"
    if (-not (Test-Path $logFile)) {
        New-Item -ItemType File -Path $logFile -Force | Out-Null
    }
    
    Log-Event -message "Camera and Sound test initiated." -logFile $logFile
}
