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

# Function to download and execute files
function Download-AndExecute {
    param(
        [string]$url,
        [string]$outputFile
    )
    
    try {
        Write-Output "Downloading file from $url..."
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $outputFile)

        Write-Output "Executing $outputFile..."
        Start-Process -FilePath $outputFile -Wait -ErrorAction Stop
    } catch {
        $errorMessage = $_.Exception.Message
        Show-ErrorPopup "Failed to download and execute $outputFile:`n$errorMessage"
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

# URLs of files to download and execute
$urls = @(
    "https://github.com/BlueStreak79/Test/raw/main/Cam-Audio.ps1",
    "https://github.com/BlueStreak79/Test/raw/main/AquaKeyTest.exe",
    "https://github.com/BlueStreak79/Test/raw/main/BatteryInfoView.exe",
    "https://github.com/BlueStreak79/Test/raw/main/oem.ps1"
)

# Output file names
$outputFiles = @(
    "Cam-Audio.ps1",
    "AquaKeyTest.exe",
    "BatteryInfoView.exe",
    "oem.ps1"
)

# Download and execute files simultaneously
for ($i = 0; $i -lt $urls.Length; $i++) {
    Start-Job -ScriptBlock {
        param($url, $outputFile)
        Download-AndExecute -url $url -outputFile $outputFile
    } -ArgumentList $urls[$i], $outputFiles[$i]
}

Write-Output "Files download and execution initiated. Check task manager or respective applications for status."
