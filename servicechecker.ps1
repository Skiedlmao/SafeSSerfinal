##############################################################################
# ServiceMonitor.ps1
# -------------------
# 1. Displays a GUI with the status of chosen services.
# 2. Lets you refresh or start services (changing them from Disabled -> Manual).
# 3. Must be run as Administrator for full functionality.
##############################################################################

# Load .NET assemblies for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# List of services you want to monitor
# Example includes DPS (Diagnostic Policy Service) and others
$services = @(
    "PcaSvc",      # Program Compatibility Assistant Service
    "SysMain",     # SysMain (was Superfetch on older Windows versions)
    "DPS",         # Diagnostic Policy Service
    "EventLog",    # Windows Event Log
    "DcomLaunch"   # DCOM Server Process Launcher
)

#############################
# Create the main form
#############################
$form = New-Object System.Windows.Forms.Form
$form.Text = "Service Monitor"
$form.Width = 420
$form.Height = 350
$form.StartPosition = "CenterScreen"
$form.Topmost = $true

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Checking Services:"
$titleLabel.AutoSize = $true
$titleLabel.Font = "Microsoft Sans Serif,12,style=Bold"
$titleLabel.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($titleLabel)

###################################
# ListView to display service info
###################################
$listView = New-Object System.Windows.Forms.ListView
$listView.View = 'Details'
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Location = New-Object System.Drawing.Point(10,50)
$listView.Size = New-Object System.Drawing.Size(380,200)

# Columns: Service Name | Status | Action
[void] $listView.Columns.Add("Service Name", 150)
[void] $listView.Columns.Add("Status", 90)
[void] $listView.Columns.Add("Action", 90)

$form.Controls.Add($listView)

# Populate the ListView with service names
foreach ($svc in $services) {
    $item = $listView.Items.Add($svc)
    # Status column (initially empty)
    [void] $item.SubItems.Add("")
    # Action column (initially empty)
    [void] $item.SubItems.Add("")
}

#################################################
# Buttons: Refresh and Start All
#################################################

# Refresh button
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh"
$refreshButton.Width = 80
$refreshButton.Height = 30
$refreshButton.Location = New-Object System.Drawing.Point(10, 265)
$form.Controls.Add($refreshButton)

# Start All button
$startAllButton = New-Object System.Windows.Forms.Button
$startAllButton.Text = "Start All"
$startAllButton.Width = 80
$startAllButton.Height = 30
$startAllButton.Location = New-Object System.Drawing.Point(100, 265)
$form.Controls.Add($startAllButton)

#################################################
# Function: Update-ServiceStatus
#   - Checks each service's status
#   - Updates the ListView's "Status" and "Action"
#################################################
function Update-ServiceStatus {
    foreach ($item in $listView.Items) {
        $svcName = $item.Text
        try {
            $service = Get-Service -Name $svcName -ErrorAction Stop
            # Check if Running
            if ($service.Status -eq "Running") {
                $item.SubItems[1].Text = "Running"
                $item.SubItems[2].Text = "None"
            }
            else {
                # Not running
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

#################################################
# Event: Refresh button
#################################################
$null = $refreshButton.Add_Click({
    Update-ServiceStatus
})

#################################################
# Event: Start All button
#   - For each service that is not running (and not "Not Found"),
#     attempt to:
#       1) If Disabled, set StartupType -> Manual
#       2) Start-Service
#   - Finally, update the service status again.
#################################################
$null = $startAllButton.Add_Click({
    foreach ($item in $listView.Items) {
        # Only attempt if not "Running" or "Not Found"
        if (($item.SubItems[1].Text -ne "Running") -and
            ($item.SubItems[1].Text -ne "Not Found")) {

            try {
                $service = Get-Service -Name $item.Text -ErrorAction Stop

                # If the service is Disabled, set it to Manual
                if ($service.StartType -eq "Disabled") {
                    Set-Service -Name $service.Name -StartupType Manual
                }

                # Attempt to start the service
                Start-Service -Name $service.Name -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to start service: $($item.Text) - $_"
            }
        }
    }

    # Refresh status after all attempts
    Update-ServiceStatus
})

# When the form is first shown, load the statuses.
$form.Add_Shown({
    Update-ServiceStatus
})

###################################
# Display the form (modal)
###################################
[void] $form.ShowDialog()
