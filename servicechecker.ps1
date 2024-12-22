Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form                = New-Object System.Windows.Forms.Form
$form.Text           = "Service Monitor"
$form.Width          = 420
$form.Height         = 350
$form.StartPosition  = "CenterScreen"
$form.Topmost        = $true

# Title label
$label               = New-Object System.Windows.Forms.Label
$label.Text          = "Checking Services:"
$label.AutoSize      = $true
$label.Font          = "Microsoft Sans Serif,12,style=Bold"
$label.Location      = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($label)

# Create a ListView to show service names and statuses
$listView            = New-Object System.Windows.Forms.ListView
$listView.View       = 'Details'
$listView.FullRowSelect  = $true
$listView.GridLines      = $true
$listView.Location   = New-Object System.Drawing.Point(10,50)
$listView.Size       = New-Object System.Drawing.Size(380,200)
$listView.Columns.Add("Service Name", 150) | Out-Null
$listView.Columns.Add("Status", 90)        | Out-Null
$listView.Columns.Add("Action", 90)        | Out-Null
$form.Controls.Add($listView)

# Service list
$services = @("Pcasvc","SysMain","DPS","EventLog","DcomLaunch")

# Populate the ListView with the service names
foreach($svc in $services) {
    $item = $listView.Items.Add($svc)
    $item.SubItems.Add("") | Out-Null  # Status (will fill later)
    $item.SubItems.Add("") | Out-Null  # Action (will fill later)
}

# Buttons
$refreshButton        = New-Object System.Windows.Forms.Button
$refreshButton.Text   = "Refresh"
$refreshButton.Width  = 80
$refreshButton.Height = 30
$refreshButton.Location = New-Object System.Drawing.Point(10, 265)
$form.Controls.Add($refreshButton)

$startAllButton        = New-Object System.Windows.Forms.Button
$startAllButton.Text   = "Start All"
$startAllButton.Width  = 80
$startAllButton.Height = 30
$startAllButton.Location = New-Object System.Drawing.Point(100, 265)
$form.Controls.Add($startAllButton)

# Function to update the service statuses
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

# Add button events
$null = $refreshButton.Add_Click({
    Update-ServiceStatus
})

$null = $startAllButton.Add_Click({
    foreach($item in $listView.Items) {
        # If it's not Running or Not Found, try to start
        if (($item.SubItems[1].Text -ne "Running") -and 
            ($item.SubItems[1].Text -ne "Not Found")) {
            try {
                Start-Service -Name $item.Text -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to start service: $($item.Text) - $_"
            }
        }
    }
    Update-ServiceStatus
})

# Initialize statuses when the form loads
$form.Add_Shown({
    Update-ServiceStatus
})

[void] $form.ShowDialog()
