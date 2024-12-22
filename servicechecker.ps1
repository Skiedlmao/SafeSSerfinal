# Requires elevated privileges.
# Save as ServiceMonitor.ps1 and run in an elevated PowerShell window.

# Load .NET assemblies for GUI components
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define the list of services to monitor
$services = @(
    "PcaSvc",      # Program Compatibility Assistant Service
    "SysMain",     # Superfetch / SysMain
    "DPS",         # Diagnostic Policy Service
    "EventLog",    # Windows Event Log
    "DcomLaunch"   # DCOM Server Process Launcher
)

# Create the main form
$form                     = New-Object System.Windows.Forms.Form
$form.Text                = "Service Monitor"
$form.Width               = 420
$form.Height              = 350
$form.StartPosition       = "CenterScreen"
$form.Topmost             = $true

# Title label
$titleLabel               = New-Object System.Windows.Forms.Label
$titleLabel.Text          = "Checking Services:"
$titleLabel.AutoSize      = $true
$titleLabel.Font          = "Microsoft Sans Serif,12,style=Bold"
$titleLabel.Location      = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($titleLabel)

# ListView to display service info
$listView                 = New-Object System.Windows.Forms.ListView
$listView.View            = 'Details'
$listView.FullRowSelect   = $true
$listView.GridLines       = $true
$listView.Location        = New-Object System.Drawing.Point(10,50)
$listView.Size            = New-Object System.Drawing.Size(380,200)
# Add columns: Service Name, Status, Action
[void] $listView.Columns.Add("Service Name", 150)
[void] $listView.Columns.Add("Status", 90)
[void] $listView.Columns.Add("Action", 90)
$form.Controls.Add($listView)

# Populate the ListView with the service names
foreach($svc in $services) {
    $item = $listView.Items.Add($svc)
    # Status column
    [void] $item.SubItems.Add("")
    # Action column
    [void] $item.SubItems.Add("")
}

# Create the Refresh button
$refreshButton            = New-Object System.Windows.Forms.Button
$refreshButton.Text       = "Refresh"
$refreshButton.Width      = 80
$refreshButton.Height     = 30
$refreshButton.Location   = New-Object System.Drawing.Point(10, 265)
$form.Controls.Add($refreshButton)

# Create the Start All button
$startAllButton           = New-Object System.Windows.Forms.Button
$startAllButton.Text      = "Start All"
$startAllButton.Width     = 80
$startAllButton.Height    = 30
$startAllButton.Location  = New-Object System.Drawing.Point(100, 265)
$form.Controls.Add($startAllButton)

# Function: Update the service statuses in the ListView
function Update-ServiceStatus {
    foreach($item in $listView.Items) {
        $svcName = $item.Text
        try {
            $service = Get-Service -Name $svcName -ErrorAction Stop
            if ($service.Status -eq "Running") {
                $item.SubItems[1].Text = "Running"
                $item.SubItems[2].Text = "None"
            }
            else {
                $item.SubItems[1].Text = $service.Status
                $item.SubItems[2].Text = "Start"
            }
        }
        catch {
            # Service not found or error retrieving status
            $item.SubItems[1].Text = "Not Found"
            $item.SubItems[2].Text = "N/A"
        }
    }
}

# Refresh button click event
$null = $refreshButton.Add_Click({
    Update-ServiceStatus
})

# Start All button click event
$null = $startAllButton.Add_Click({
    foreach($item in $listView.Items) {
        # Only attempt to start if not running or not "Not Found"
        if (($item.SubItems[1].Text -ne "Running") -and
            ($item.SubItems[1].Text -ne "Not Found")) {
            try {
                $service = Get-Service -Name $item.Text -ErrorAction Stop
                # If disabled, set to Manual before trying to start
                if ($service.StartType -eq "Disabled") {
                    Set-Service -Name $service.Name -StartupType Manual
                }
                Start-Service -Name $service.Name -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to start service: $($item.Text). Error: $_"
            }
        }
    }
    # Refresh status after attempts
    Update-ServiceStatus
})

# Initialize statuses when the form first shows
$form.Add_Shown({
    Update-ServiceStatus
})

# Display the form (modal)
[void] $form.ShowDialog()
