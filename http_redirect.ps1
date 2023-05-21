$serverName = $args[0]
$applicationName = $args[1]
$siteName = $args[2]
$httpRedirectTo = $args[3]

#Write-Host "Server name is: $serverName"
#Write-Host "applicationName name is: $applicationName"
#Write-Host "siteName name is: $siteName"

Write-Host "========================================================" 

Invoke-Command -ComputerName $serverName -Script { 
    param($serverName,$applicationName,$siteName,$httpRedirectTo) 
    Write-Host "Redirect http requests  for application $applicationName to: $httpRedirectTo"
    C:\Windows\System32\inetsrv\appcmd.exe set config "$siteName/$applicationName" -section:system.webServer/httpRedirect /enabled:"True"
    C:\Windows\System32\inetsrv\appcmd.exe set config "$siteName/$applicationName" -section:system.webServer/httpRedirect /destination:"$httpRedirectTo"
    C:\Windows\System32\inetsrv\appcmd.exe set config "$siteName/$applicationName" -section:system.webServer/httpRedirect /exactDestination:"True"
    C:\Windows\System32\inetsrv\appcmd.exe set config "$siteName/$applicationName" -section:system.webServer/httpRedirect /httpResponseStatus:"Found"
    
     } -argumentlist $serverName,$applicationName,$siteName,$httpRedirectTo


Write-Host "========================================================"





    
