param($hostname='yahoo.com',[int[]]$ports=(80,443),$upload="192.168.119.176:8080",$timeout=100,$openPorts=$True)
$requestCallback = $state = $null
$output = New-Object Collections.Generic.List[psobject]
$p = (Get-Random -Minimum 10000 -Maximum 65000)
foreach ($port in $ports) {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.BeginConnect($hostname,$port,$requestCallback,$state) | Out-Null
    Start-Sleep -milli $timeOut
    if ($client.Connected) { $open = $true } else { $open = $false }
    $client.Close()
    $props = @{hostname=$hostname;port=$port;open=$open;redirect=$false;}
    if ($openPorts -and $open) {
        #
        $p += 1
        $props['redirect'] = $p
        write-host $(& netsh interface portproxy set v4tov4 listenport=$p listenaddress=10.11.1.31 connectport=$port connectaddress=$hostname )
    }
    $obj = [pscustomobject]$props
    $output.Add($obj)
    $obj;
}
if ($upload) {
    $outfilename = 'portscan' + '_' + (Get-Date).ToFileTimeUtc() + '.output';
    $outfilepth = 'c:\temp\'+$outfilename;
    $output | Export-Csv $outfilepth -Force -NoTypeInformation;
    Invoke-RestMethod -Uri "http://$upload/$hostname/$outfilename" -Method POST -UseDefaultCredentials -Body (convertto-json $output) ;
    Invoke-RestMethod -Uri "http://$upload/$hostname/$outfilename" -Method Put -UseDefaultCredentials -InFile $outfilepth ;
}
return $output
