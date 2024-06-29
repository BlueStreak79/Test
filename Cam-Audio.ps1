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

# Function to set execution policy temporarily
function Set-ExecutionPolicyTemp {
    param(
        [string]$policy
    )
    try {
        Set-ExecutionPolicy $policy -Scope Process -Force -ErrorAction Stop
    } catch {
        Write-Error "Failed to set execution policy. Script will continue with current policy."
    }
}

# Function to open Camera app
function Open-Camera {
    try {
        Write-Output "Opening Camera app..."
        Start-Process -FilePath "microsoft.windows.camera:" -ErrorAction Stop
    } catch {
        $errorMessage = $_.Exception.Message
        Show-ErrorPopup "Failed to open Camera app:`n$errorMessage"
    }
}

# Function to open Sound settings
function Open-SoundSettings {
    try {
        Write-Output "Opening Sound settings..."
        Start-Process -FilePath "control.exe" -ArgumentList "/name Microsoft.Sound" -ErrorAction Stop
    } catch {
        $errorMessage = $_.Exception.Message
        Show-ErrorPopup "Failed to open Sound settings:`n$errorMessage"
    }
}

# Function to show error popup
function Show-ErrorPopup {
    param(
        [string]$message
    )
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($message, "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
}

# Main script execution
Request-Elevation

# Set execution policy temporarily
Set-ExecutionPolicyTemp -policy RemoteSigned

# Open Camera app
Open-Camera

# Open Sound settings
Open-SoundSettings

# Reset execution policy to Restricted (optional)
# Set-ExecutionPolicy Restricted -Scope Process -Force
