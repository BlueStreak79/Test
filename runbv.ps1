$ErrorActionPreference = "Stop"
# Enable TLSv1.2 for compatibility with older clients
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# URL of the file to download
$DownloadURL = "https://github.com/BlueStreak79/Test/raw/refs/heads/main/BatteryInfoView.exe"

# Path to save the downloaded file
$FilePath = "$env:TEMP\BatteryViewInfo.exe"

try {
    # Check if the file already exists
    if (-not (Test-Path $FilePath)) {
        # Download the file
        Write-Host "Downloading $DownloadURL..."
        Invoke-WebRequest -Uri $DownloadURL -OutFile $FilePath -UseBasicParsing

        # Check if download was successful
        if (-not (Test-Path $FilePath)) {
            throw "Download failed."
        }
        Write-Host "Download completed."
    } else {
        Write-Host "File already exists. Skipping download."
    }

    # Execute the downloaded file
    Write-Host "Executing BatteryViewInfo.exe..."
    Start-Process -FilePath $FilePath -Wait
    Write-Host "BatteryViewInfo.exe execution completed."
}
catch {
    Write-Error "An error occurred: $_"
}
