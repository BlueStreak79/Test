# Function to check if the script is running with admin privileges
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to set the execution policy
function Set-ExecutionPolicyUnrestricted {
    try {
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
    } catch {
        Write-Error "Failed to set execution policy: $_"
        exit 1
    }
}

# Check if the script is running with admin privileges
if (-not (Test-Admin)) {
    Write-Error "This script must be run as an administrator."
    exit 1
}

# Set the execution policy to unrestricted for the current process
Set-ExecutionPolicyUnrestricted

# Load necessary assemblies
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    Write-Error "Failed to load necessary assemblies: $_"
    exit 1
}

# Log file path
$logFile = "$env:USERPROFILE\Desktop\key_log.txt"

# Log key presses to a file
function Log-KeyPress {
    param ($key)
    try {
        Add-Content -Path $logFile -Value ("$key")
    } catch {
        Write-Error "Failed to write to log file: $_"
    }
}

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Keyboard Tester"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"
$form.KeyPreview = $true

# Create a label to display instructions
$label = New-Object System.Windows.Forms.Label
$label.Text = "Press any key. Press ESC to exit."
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($label)

# Create a list box to display key presses
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(260, 80)
$listBox.Location = New-Object System.Drawing.Point(10, 40)
$form.Controls.Add($listBox)

# Logging state
$loggingEnabled = $false

# Start logging button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Logging"
$startButton.Location = New-Object System.Drawing.Point(10, 130)
$startButton.Add_Click({
    $loggingEnabled = $true
    $listBox.Items.Add("Logging started")
})
$form.Controls.Add($startButton)

# Stop logging button
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop Logging"
$stopButton.Location = New-Object System.Drawing.Point(150, 130)
$stopButton.Add_Click({
    $loggingEnabled = $false
    $listBox.Items.Add("Logging stopped")
})
$form.Controls.Add($stopButton)

# Create a panel to visualize the keyboard
$keyboardPanel = New-Object System.Windows.Forms.Panel
$keyboardPanel.Size = New-Object System.Drawing.Size(260, 50)
$keyboardPanel.Location = New-Object System.Drawing.Point(10, 70)
$form.Controls.Add($keyboardPanel)

# Define a function to draw a simple keyboard
function Draw-Keyboard {
    param ($panel)
    $panel.Controls.Clear()
    $keys = "QWERTYUIOPASDFGHJKLZXCVBNM"
    $x = 10
    $y = 10
    $keys.ToCharArray() | ForEach-Object {
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $_
        $button.Size = New-Object System.Drawing.Size(20, 20)
        $button.Location = New-Object System.Drawing.Point($x, $y)
        $panel.Controls.Add($button)
        $x += 25
        if ($x > 200) {
            $x = 10
            $y += 25
        }
    }
}

# Call the function to draw the keyboard
Draw-Keyboard -panel $keyboardPanel

# Define the key down event handler
$keyDownHandler = {
    param ($sender, $eventArgs)
    $key = $eventArgs.KeyCode
    $modifiers = @()
    if ($eventArgs.Shift) { $modifiers += "Shift" }
    if ($eventArgs.Control) { $modifiers += "Ctrl" }
    if ($eventArgs.Alt) { $modifiers += "Alt" }
    $modifiersText = if ($modifiers.Count -gt 0) { $modifiers -join '+' } else { "None" }
    $listBox.Items.Add("Key pressed: $key (Modifiers: $modifiersText)")
    $listBox.SelectedIndex = $listBox.Items.Count - 1  # Scroll to the last item
    $keyboardPanel.Controls | ForEach-Object {
        if ($_.Text -eq $key.ToString()) {
            $_.BackColor = [System.Drawing.Color]::Yellow
        }
    }
    if ($loggingEnabled) {
        Log-KeyPress -key "Key pressed: $key (Modifiers: $modifiersText)"
    }
    if ($key -eq 'Escape') {
        $form.Close()
    }
}

# Define a function to reset key colors on key up
$keyUpHandler = {
    param ($sender, $eventArgs)
    $key = $eventArgs.KeyCode
    $keyboardPanel.Controls | ForEach-Object {
        if ($_.Text -eq $key.ToString()) {
            $_.BackColor = [System.Drawing.Color]::Control
        }
    }
}

# Attach the key down and key up event handlers to the form
$form.Add_KeyDown($keyDownHandler)
$form.Add_KeyUp($keyUpHandler)

# Error handling for form display
try {
    # Show the form
    $form.ShowDialog() | Out-Null
} catch {
    Write-Error "An error occurred while displaying the form: $_"
    exit 1
}
