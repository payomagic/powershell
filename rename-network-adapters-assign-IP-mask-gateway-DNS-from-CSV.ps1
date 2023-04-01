# Load the CSV file containing the adapter names, new names, IP addresses, subnet masks, default gateways, and DNS servers
# CSV file has a header row with the column names "OldName", "NewName", "IPAddress", "SubnetMask", "DefaultGateway", and "DNSServer"
$adapters = Import-Csv -Path "E:\adapters.csv"

# Loop through each adapter and rename it, set its IP address, subnet mask, default gateway, and DNS server
foreach ($adapter in $adapters) {
    $oldName = $adapter.OldName
    $newName = $adapter.NewName
    $ipAddress = $adapter.IPAddress
    $subnetMask = $adapter.SubnetMask
    $DefaultGateway = $adapter.DefaultGateway
    $DNSServer = $adapter.DNSServer

    $networkAdapter = Get-NetAdapter -Name $oldName
    if ($networkAdapter) {
        Rename-NetAdapter -Name $oldName -NewName $newName
        Write-Host "Renamed adapter '$oldName' to '$newName'"

        # Set the adapter's IP address, subnet mask, default gateway, and DNS server
        $adapterConfig = Get-NetAdapterAdvancedProperty -Name $newName -RegistryKeyword IPAddress
        if ($adapterConfig) {
            Set-NetIPAddress -InterfaceAlias $newName -IPAddress $ipAddress -PrefixLength $subnetMask
            Set-NetIPInterface -InterfaceAlias $newName -DefaultGateway $defaultGateway
            Set-DnsClientServerAddress -InterfaceAlias $newName -ServerAddresses $dnsServer
            Write-Host "Set IP address '$ipAddress', subnet mask '$subnetMask', default gateway '$defaultGateway', and DNS server '$dnsServer' for adapter '$newName'"
        } else {
            Write-Host "Could not find registry key for IP address on adapter '$newName'"
        }
    } else {
        Write-Host "Could not find adapter '$oldName'"
    }
}
