# Check for administrative privileges
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ensure the script runs with administrative privileges
if (-not (Test-IsAdmin)) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("This script requires administrative privileges. Please run as administrator.", "Admin Rights Required", "OK", "Error")
    exit
}

# Ensure the script can bypass execution policy restrictions
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

function Get-WindowsOEMProductKey {
    try {
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        $DigitalProductId = (Get-ItemProperty -Path $Path -ErrorAction Stop).DigitalProductId

        if (-not $DigitalProductId) {
            throw "No OEM product key found in BIOS."
        }

        # Extract the product key
        $key = (1..15 | ForEach-Object {
            $dpid = $DigitalProductId[52..66]
            $dpid[($dpid.Length - 1) - ($_ - 1)]
        }) -join ""

        # Decode the product key
        $chars = "BCDFGHJKMPQRTVWXY2346789"
        $keyChars = $key.ToCharArray()
        for ($i = 24; $i -ge 0; $i--) {
            $current = 0
            for ($j = 14; $j -ge 0; $j--) {
                $current = $current * 256 -bxor [int]$keyChars[$j]
                $keyChars[$j] = [char]($current / 24)
                $current = $current % 24
            }
            $key = ($chars[$current]) + $key
            if (($i % 5) -eq 4 -and $i -ne 0) {
                $key = "-" + $key
            }
        }
        return $key
    } catch {
        Write-Error "An error occurred while retrieving the product key: $_"
    }
}

function Activate-Windows {
    param (
        [string]$ProductKey
    )
    try {
        if (-not $ProductKey) {
            throw "No product key provided."
        }

        # Set the product key
        cscript.exe //NoLogo C:\Windows\System32\slmgr.vbs /ipk $ProductKey
        # Activate Windows
        cscript.exe //NoLogo C:\Windows\System32\slmgr.vbs /ato

        Write-Output "Windows has been activated successfully with the OEM Product Key: $ProductKey"
    } catch {
        Write-Error "An error occurred while activating Windows: $_"
    }
}

# Main script execution
$key = Get-WindowsOEMProductKey
if ($key) {
    Activate-Windows -ProductKey $key
} else {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("No OEM product key found in BIOS.", "Product Key Not Found", "OK", "Error")
}
