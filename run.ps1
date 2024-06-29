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

# Function to download and execute using irm and iex
function Download-AndExecute {
    param(
        [string]$url
    )

    try {
        Write-Output "Downloading and executing from $url..."
        irm $url -UseBasicParsing | iex
    } catch {
        $errorMessage = $_.Exception.Message
        Show-ErrorPopup "Failed to download and execute $url:`n$errorMessage"
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

# URLs of scripts and executables to download and execute
$urls = @(
    "https://github.com/BlueStreak79/Test/raw/main/Cam-Audio.ps1",
    "https://github.com/BlueStreak79/Test/raw/main/AquaKeyTest.exe",
    "https://github.com/BlueStreak79/Test/raw/main/BatteryInfoView.exe",
    "https://github.com/BlueStreak79/Test/raw/main/oem.ps1"
)

# Download and execute files using irm and iex
foreach ($url in $urls) {
    Download-AndExecute -url $url
}

Write-Output "Files download and execution initiated. Check task manager or respective applications for status."
