#set variables
$vcenter = "vcenter.domain.com"
$cluster = "Clustername"

connect-viserver $vcenter #comment this line out if you are already connected to your vCenter
$ESXiServers = get-cluster -name $cluster | get-vmhost

# Reboot ESXi Server Function
Function RebootESXiServer ($CurrentServer) {

# Get VI-Server name
$ServerName = $CurrentServer.Name

# Put server in maintenance mode
Write-Host "** Rebooting $ServerName **"
Write-Host "Entering Maintenance Mode"
Set-VMhost $CurrentServer -State maintenance -Evacuate -vsandatamigrationmode EnsureAccessibility | Out-Null

# Reboot host
Write-Host "Rebooting"
Restart-VMHost $CurrentServer -confirm:$false | Out-Null

# Wait for Server to show as down
do {
sleep 15
$ServerState = (get-vmhost $ServerName).ConnectionState
}

while ($ServerState -ne "NotResponding")
Write-Host "$ServerName is Down"

# Wait for server to reboot
do {
sleep 60
$ServerState = (get-vmhost $ServerName).ConnectionState
Write-Host "Waiting for Reboot …"
}

while ($ServerState -ne "Maintenance")
Write-Host "$ServerName is back up"

# Exit maintenance mode
Write-Host "Exiting Maintenance mode"
Set-VMhost $CurrentServer -State Connected | Out-Null
Write-Host "** Reboot Complete **"
Write-Host ""
}

## MAIN
foreach ($ESXiServer in $ESXiServers) {
RebootESXiServer ($ESXiServer)
}

# Disconnect from vCenter
Disconnect-VIServer
