$ScriptName = 'http_redirect.ps1'
$CurrentDirectory = Get-Location
$fullpath = join-path -path $CurrentDirectory -childpath $ScriptName

$serverName = $args[0] 
$siteName =  $args[1]
$Address =  $args[2]

Write-Host "Script start ..." 
Write-Host "Pasrams are: "
Write-Host "serverName: $serverName"
Write-Host "siteName: $siteName"
Write-Host "Address: $Address"

$Applications = "benny2","benny3","benny4"
foreach ($app in $Applications)
{ 
  & $fullpath $serverName $app $siteName $Address
}

