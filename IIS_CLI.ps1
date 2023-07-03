Import-Module IISAdministration -Verbose:$false
Import-Module WebAdministration


$global:serverName = "def_servername"

function Format-Color([hashtable] $Colors = @{}, [switch] $SimpleMatch) {
	$lines = ($input | Out-String) -replace "`r", "" -split "`n"
	foreach($line in $lines) {
		$color = ''
		foreach($pattern in $Colors.Keys){
			if(!$SimpleMatch -and $line -match $pattern) { $color = $Colors[$pattern] }
			elseif ($SimpleMatch -and $line -like $pattern) { $color = $Colors[$pattern] }
		}
		if($color) {
			Write-Host -ForegroundColor $color $line
		} else {
			Write-Host $line
		}
	}
}

function backup_application([string]$application_name) #work with 2012 and 2016
{
  write-host "Search for application: $application_name on server $global:serverName"
  $Output = Invoke-Command -ComputerName $global:serverName { 
   param($application_name) 
   Import-Module WebAdministration
   
   $res = dir IIS:\Sites | ForEach-Object {
  Get-WebApplication -Site $_.Name -Name $application_name
  
  }

write-host "application found"
$res 
$srcPath = $res.PhysicalPath 
$time = (Get-Date).ToString("dd.MM.yyyy_HH_mm_ss")
$dstPath = $res.PhysicalPath + "_" + $time 
write-host "creating backup ..."
cp -r $srcPath $dstPath
write-host "Backup created on server."
$dotnetFolder =  (Split-Path $srcPath)

$str = ""
dir $dotnetFolder | ForEach-Object {
  $str += "`n$_"
}

$heretext = @"
$str
"@

foreach($item in $res)
{
#$item.applicationPool
#write-host "bla 1"
#$item.PhysicalPath
#write-host "bla 2"
}

  return @{
    dirDotNetFolder = $heretext
    bkpFolderName = $application_name + "_" + $time
  }

  } -argumentlist $application_name

  $folderNameForColor = $Output.bkpFolderName[1] # the return value is array and the string is in x[1]
  $Output.dirDotNetFolder  | Format-Color @{$folderNameForColor = 'green'}
  #$String  | Format-Color @{'^benny2_20.06.2023_14_16_46\s+: False|^Enabled\s+: True' = 'Green'}
  return $res   
}


function create_app_pool_list([string]$_state)
{

  $testArray = New-Object System.Collections.Generic.List[System.Object]


  if ( $global:serverName -like "*2012*") { 
    #Write-host "server is 2012"

    if($_state -EQ "All") {

      $resultsa = Invoke-Command -ComputerName $global:serverName { 
        param($_state) 
        $appCmd = "C:\Windows\System32\inetsrv\appcmd.exe"
        $appcmd_args = " list apppool"
        #$appcmd_args = " list apppool  /State:$_state"
        $AppCmd_Commnd = [string]::Format("{0} {1}", $appCmd, $appcmd_args)
        iex $AppCmd_Commnd

      } -argumentlist $_state

      

   }else {
    $resultsa = Invoke-Command -ComputerName $global:serverName { 
        param($_state) 
        $appCmd = "C:\Windows\System32\inetsrv\appcmd.exe"
        $appcmd_args = " list apppool  /State:$_state"
        $AppCmd_Commnd = [string]::Format("{0} {1}", $appCmd, $appcmd_args)
        iex $AppCmd_Commnd

      } -argumentlist $_state

   }


   foreach ($item in $resultsa) {

    #$item    #APPPOOL "NrsNet" (MgdVersion:,MgdMode:Integrated,state:Stopped)
    $CharArray =$item.Split(" ")
    #APPPOOL
    #"NrsNet"
    #(MgdVersion:,MgdMode:Integrated,state:Stopped)
    #$CharArray[1] #"NrsNet"
    #$CharArray[1].Replace("`"","")   NrsNet
    $appPoolName = $CharArray[1]
    
    
    #$appPoolName 
    #$appPoolName_rep = $CharArray[1].Replace("`"","")
    write-host "after replace $appPoolName"
    
  
       $tmpArray = New-Object System.Collections.Generic.List[System.Object]
   
       $tmpArray.Add(($CharArray[1].Replace("`"","")))
       
       $testArray+=$tmpArray
   
       $PSComputerName = $item.PSComputerName
         
   } 




  }
  else 
  {

    if($_state -EQ "All") {

      $resultsa = Invoke-Command -ComputerName $global:serverName { 
           param($_state) 
           Get-IISAppPool 
      } -argumentlist $_state

      

      
   }else {
      $resultsa = Invoke-Command -ComputerName $global:serverName { 
           param($_state) 
           Get-IISAppPool | Where-Object -FilterScript {$_.State -EQ "$_state"}
      } -argumentlist $_state

   }


   foreach ($item in $resultsa) {

       $tmpArray = New-Object System.Collections.Generic.List[System.Object]
   
       $tmpArray.Add(($item.Name))
       
       $testArray+=$tmpArray
   
       $PSComputerName = $item.PSComputerName
         
   } 



    Write-host "server is not 2012"
  }



 return $testArray

}

function get_server()
{
  write-host "Server name is: $global:serverName"
}


 
function set_server([string]$_server_name)
{
  write-host "Server name update from: $global:serverName"
  $serverName = $_server_name
  write-host "to: $serverName"
  return $serverName

}



function get_iis_sites([string]$_app_pool_name)
 {
     Invoke-Command -ComputerName $global:serverName { 
          param($_app_pool_name) 
          $Websites = Get-IISSite

          foreach ($Website in $Websites) {
            write-host $Website
              write-host "blabla1"

            foreach ($x in $Website) {
              write-host $x
              write-host "blabla2"
            }
      
              $AppPool = Get-IISAppPool -Name $Website.Applications[0].ApplicationPoolName
      
              [PSCustomObject]@{
                  Website_Name                  = $Website.Name
                  Website_Id                    = $Website.Id -join ';'
                  Website_State                 = $Website.State -join ';'
                  Website_PhysicalPath          = Get-Item IIS:\Sites\$Website | Select-Object -ExpandProperty physicalPath
                  Website_Bindings              = $Website.Bindings.Collection -join ';'
                  Website_Attributes            = ($Website.Attributes | ForEach-Object { $_.name + "=" + $_.value }) -join ';'
                  AppPool_Name                  = $AppPool.Name -join';'
                  AppPool_State                 = $AppPool.State -join ';'
                  AppPool_ManagedRuntimeVersion = $AppPool.ManagedRuntimeVersion -join ';'
                  AppPool_ManagedPipelineMode   = $AppPool.ManagedPipelineMode -join ';'
                  AppPool_StartMode             = $AppPool.StartMode -join ';'
              }
          }

     } -argumentlist $_app_pool_name
     
 }

function recycle_app_pool([string]$_app_pool_name)
 {
  write-host "recycle_app_pool start, param is: $_app_pool_name"
     Invoke-Command -ComputerName $global:serverName { 
          param($_app_pool_name) 
          
          $appCmd = "C:\Windows\System32\inetsrv\appcmd.exe"
          $appcmd_args = "recycle  apppool /apppool.name:$_app_pool_name"
          $AppCmd_Commnd = [string]::Format("{0} {1}", $appCmd, $appcmd_args)
          #write-host "AppCmd_Commnd is: $AppCmd_Commnd"
          iex $AppCmd_Commnd


     } -argumentlist $_app_pool_name
     
 }





 function get_application_pool_by_name([string]$_app_pool_name)
 {
  
  write-host ""
  write-host "================================================================="

  if ( $global:serverName -like "*2012*") 
  {
    Invoke-Command -ComputerName $global:serverName { 
      param($_app_pool_name) 

      $appCmd = "C:\Windows\System32\inetsrv\appcmd.exe"
        $appcmd_args = " list apppool /apppool.name:$_app_pool_name"
        $AppCmd_Commnd = [string]::Format("{0} {1}", $appCmd, $appcmd_args)
        iex $AppCmd_Commnd


  } -argumentlist $_app_pool_name
    
  }
  else
  {
    Invoke-Command -ComputerName $global:serverName { 
      param($_app_pool_name) 
      Get-IISAppPool -Name $_app_pool_name
  } -argumentlist $_app_pool_name

  }

  write-host "================================================================="
  write-host ""
  

 }


 function start_app_pool([string]$_app_pool_name)
 {
     Invoke-Command $global:serverName { 
          param($_app_pool_name) 
          Start-WebAppPool -Name $_app_pool_name
     } -argumentlist $_app_pool_name
     
     write-host ""
     write-host "the stop-app-pool function finished, the corrent state of application pool $_app_pool_name is:"
     get_application_pool_by_name($_app_pool_name)
     


 }

 function stop_app_pool([string]$_app_pool_name)
 {
     Invoke-Command $global:serverName { 
          param($_app_pool_name) 
          Stop-WebAppPool -Name $_app_pool_name
     } -argumentlist $_app_pool_name

     
     write-host "the stop-app-pool function finished, the corrent state of application pool: $_app_pool_name is:"
     get_application_pool_by_name($_app_pool_name)
     
 }


 function get_app_pool_data([string]$_app_pool_name)
 {
     Invoke-Command -ComputerName $global:serverName { 
          param($_app_pool_name) 
         
            c:\Windows\System32\inetsrv\appcmd.exe list apppool $_app_pool_name /text:*

     } -argumentlist $_app_pool_name
     
 }

 function get_all_app_pools_data([string]$_app_pool_name)
 {
  write-host "get_all_app_pools_data start ...."
  #$script_b = {c:\Windows\System32\inetsrv\appcmd.exe list apppool $Pkt /text:* | Select-String -Pattern "userName" | select line}
     
  #Invoke-Command -script $script_b -ComputerName $global:serverName
  $applicationPoolList = create_app_pool_list("All")

  write-host "applicationPoolList: $applicationPoolList"

  foreach ($applicationPool in $applicationPoolList) {
    get_app_pool_app_user_data($applicationPool)
  }
     
 }


 function get_app_pool_app_user_data([string]$_app_pool_name) #7
 {


  $cmd_userName = "c:\Windows\System32\inetsrv\appcmd.exe list apppool $_app_pool_name /text:* | Select-String -Pattern `"userName`" | select line" 
  $cmd_password = "c:\Windows\System32\inetsrv\appcmd.exe list apppool $_app_pool_name /text:* | Select-String -Pattern `"password`" | select line" 

  $scriptBlock_user = [Scriptblock]::Create($cmd_userName)
  $scriptBlock_pass = [Scriptblock]::Create($cmd_password)


  if (!$scriptBlock_user) 
  {
     write-host "user is: $scriptBlock_user is empty, skipped"
  }
  else
  {
    Invoke-Command -script $scriptBlock_user -ComputerName $global:serverName
    Invoke-Command -script $scriptBlock_pass -ComputerName $global:serverName
  }


    #$i = 0 # helper index var.
#foreach ($userName in $userName_script) { # enumerate $services directly
#
#   # Using the index variable, find the corresponding element from 
#   # the 2nd collection, $startupTypes, then increment the index.
#   $passwordtmp = $password_script[$i++]
#
#   write-host "user: $userName password: $passwordtmp"
#
#   # Now process $service and $startupType as needed.
#}
   
   
 }

 
 function get_app_pool_app_user_data_with_with_job([string]$_app_pool_name)  #7
 {

  $userName_script = {c:\Windows\System32\inetsrv\appcmd.exe list apppool "$Pkt" /text:* | Select-String -Pattern "userName" |select line}
  $password_script = {c:\Windows\System32\inetsrv\appcmd.exe list apppool "$Pkt" /text:* | Select-String -Pattern "password" |select line}

    $job=Invoke-Command -script $userName_script -ComputerName $global:serverName -AsJob
    wait-job $job
    $job|receive-job -keep | select line


    $job=Invoke-Command -script $password_script -ComputerName $global:serverName -AsJob
    wait-job $job
    $job|receive-job -keep | select line
 }

 function get_web_application_with_phisycal_path([string]$def_val) #work with 2012 and 2016
 {
  Invoke-Command -ComputerName $global:serverName { 
    param($_state) 
    Import-Module WebAdministration
    dir IIS:\Sites | ForEach-Object {
   # Web site name
   #$_.Name
   # Site's app pool
   #$_.applicationPool
   # Any web applications on the site + their app pools
   Get-WebApplication -Site $_.Name
    }
  } -argumentlist $_state     
}





 function get_web_application_data([string]$def_val)
 {
  Invoke-Command -ComputerName $global:serverName { 
    param($_state) 
    #Import-Module WebAdministration

    dir IIS:\Sites | ForEach-Object {

   # Web site name
   $_.Name

   # Site's app pool
   $_.applicationPool

   # Any web applications on the site + their app pools
   Get-WebApplication -Site $_.Name
}

} -argumentlist $_state
     
 }


function Print-Table([Array[]]$_results) {
     $testArray = New-Object System.Collections.Generic.List[System.Object]

     foreach ($item in $_results) {
     
          $tmpArray = New-Object System.Collections.Generic.List[System.Object]
      
          $tmpArray.Add(($item.Name,$item.State, $item.PSComputerName))
          
          $testArray+=$tmpArray
      
          $appPool = $item.Name
      
          $status = $item.State
      
          $PSComputerName = $item.PSComputerName
            
      } 
      foreach ($currentItemName in $testArray) {
          #write-host "in function loop"
          #write-host $currentItemName[1]
     }

     write-host "start print with colors"
     foreach ($line in $tmpArray) {
      $m = $rx.match($line)
      #only process if there is a match
    if ($m.success) {
      #get the point in the string where the match starts
      $i = $m.Index
      #display the line from start up to the match
      $line.Substring(0,$i) | write-host -NoNewline
      #select a foreground color based on matching status. Default should never be reached
    switch -Regex ($m.value) {
      "Stopped" { $fg = "Red" }
      "Started" { $fg = "Green" }
      "Pending" { $fg = "Magenta" }
      "Paused" { $fg = "Yellow" }
      Default { Write-Warning "Somehow there is an unexpected status" }
    }
      $line.substring($i) | Write-Host -ForegroundColor $fg
    }
    else {
      #just write the line as is if no match
      Write-Host $line
    }
  } #close foreach
 }

 function Print-Table-butify([Array[]]$_results) {

     write-host "Print-Table-butify started"

     $tableArray = New-Object System.Collections.Generic.List[System.Object]

     foreach ($item in $_results) {
          $tmpArray = New-Object System.Collections.Generic.List[System.Object]
          $tmpArray.Add(($item.Name,$item.State, $item.PSComputerName))
          $tableArray+=[pscustomobject]@{Name = $item.Name; State = $item.State; PSComputerName =$item.PSComputerName}
     } 
     #$tableArray | Format-Table
     #$tmpArray | Format-Table
      #$tmpArray
      $tableArray
 }


 function print_get-app-pools_res([System.Array]$x)
 {
  $x  | Format-Color @{'state:Started' = 'green';'state:Stopped' = 'Red';}
    
      write-Host "print_get-app-pools_res start"
      foreach ($s in $x)
      {
        $r = $($s -replace '\s+', ' ').split("APPPOOL")
        write-Host "s ----- +${s} "\
        write-Host $s.GetType()
        write-Host $r.GetType()
        
        write-Host $s[1]
      }
    
 }

 function print_get-app-pools_res_colored([System.Array]$x)
 {
  
  $x  | Format-Color @{'state:Started|Started' = 'green';'state:Stopped|Stopped' = 'Red';}
  
 }


 function get-app-pools([string]$_state) {
  Write-Host "get-app-pools start, server name is $global:serverName, state parameter is: $_state"
  if ( $global:serverName -like "*2012*") { 
    #Write-host "server is 2012"
    if($_state -EQ "All") {
     
      $resultsa = Invoke-Command -ComputerName $global:serverName { 
        param($_state) 
        $appCmd = "C:\Windows\System32\inetsrv\appcmd.exe"
        $appcmd_args = " list apppool"
        #$appcmd_args = " list apppool  /State:$_state"
        $AppCmd_Commnd = [string]::Format("{0} {1}", $appCmd, $appcmd_args)
        iex $AppCmd_Commnd

      } -argumentlist $_state


     
     
   }else {
    $resultsa = Invoke-Command -ComputerName $global:serverName { 
        param($_state) 
        $appCmd = "C:\Windows\System32\inetsrv\appcmd.exe"
        $appcmd_args = " list apppool  /State:$_state"
        $AppCmd_Commnd = [string]::Format("{0} {1}", $appCmd, $appcmd_args)
        iex $AppCmd_Commnd

      } -argumentlist $_state
   }
  }
  else 
  {
    if($_state -EQ "All") {

      $resultsa = Invoke-Command -ComputerName $global:serverName { 
           param($_state) 
           Get-IISAppPool 
      } -argumentlist $_state

     
   }else {
      $resultsa = Invoke-Command -ComputerName $global:serverName { 
           param($_state) 
           Get-IISAppPool | Where-Object -FilterScript {$_.State -EQ "$_state"}
      } -argumentlist $_state

  }

  #foreach ($res in $resultsa)
  #{
  #    Write-host "blabla ========================== $res "
  #}
 
    $resultsa = Print-Table-butify($resultsa)
   
    
  
   
 }

 return $resultsa

}



 function application-pool-Menu {
     
     param (
         [string]$Title = 'application-pool-Menu'
     )
     Write-Host "Start application-pool-Menu function" 

     
     do
     {
      Clear-Host
          write-host "server name is: $global:serverName"
          Write-Host "================ $Title ================"
          Write-Host "1:  press '1' Show all."
          Write-Host "2:  press '2' Show Stopped Application pools."
          Write-Host "3:  press '3' Show Started Application pools."
          Write-Host "4:  press '4' Start Application pool."
          Write-Host "5:  press '5' Stop Application pool."
          Write-Host "6:  press '6' get application pool data."
          Write-Host "7:  press '7' get application pool user and password."
          Write-Host "8:  press '8' get all application pools users and passwords."
          Write-Host "9:  press '9' search application pool."
          Write-Host "10: press '10' recycle application pool."
          Write-Host "m:  press 'm' go back to main-menu."
          write-host "s:  press 's' change server."

        $selection = Read-Host "Please make a selection"
        
        switch ($selection)
        {
        '1' {
          'You chose to Show all application pools #1'
        #get-app-pools("All")  
        
        print_get-app-pools_res_colored(get-app-pools("All"))
     
        } '2' {
        'You chose option #2'
         print_get-app-pools_res_colored(get-app-pools("Stopped"))
        } '3' {
          'You chose option #3'
          print_get-app-pools_res_colored(get-app-pools("Started"))
        }
        '4' {
          'You chose option #4'
          $application_pool_Nane = Read-Host "Please enter application pool name to start"
          start_app_pool("$application_pool_Nane")
        }
        '5' {
          'You chose option #5'
          $application_pool_Nane = Read-Host "Please enter application pool name to stop"
          stop_app_pool("$application_pool_Nane")
          
        }
        '6' {
          'You chose option #6'
          #cin app pool name
          $application_pool_Name = Read-Host "Please enter application pool name"
          get_app_pool_data($application_pool_Name)
        }
        '7' {
          'You chose option #7'
          $application_pool_Name = Read-Host "Please enter application pool name"
          get_app_pool_app_user_data($application_pool_Name)
        } 
        '8' {

          get_all_app_pools_data("dev_val")
        } 
        '9' {
          'You chose option #9 Search application pool'
          $application_pool_Name = Read-Host "Please enter application pool name."
          get_application_pool_by_name($application_pool_Name)
        } 
        '10' {
          
          $application_pool_Name = Read-Host "Please enter application pool name to recycle"
          recycle_app_pool($application_pool_Name)
        } 
        'm' {
          main-Menu
        }
        
        's' {
          server-menu
        }
        'q' {
          write-host "--------------------------Finish--------------------------------"
          exit 
        }
        }
        pause
     }
     until ($selection -eq 'q')

 }


 function web-site-Menu {
     
     param (
         [string]$Title = 'web-site-Menu'
     )
     Write-Host "web-site-Menu" 
     
     do
     {
          Clear-Host
          write-host "server name is: $global:serverName"
          Write-Host "================ $Title ================"
          Write-Host "1: Show all Sites."
          Write-Host "2: Show All WebApplication."
          Write-Host "3: backup WebApplication."
          Write-Host "m: to main menu."
          write-host "s: change server:"
        $selection = Read-Host "Please make a selection"
        
        switch ($selection)
        {
        '1' {
          'Show all Sites. #1'
        get_iis_sites("dev_val")
        
     
        } '2' {
        'Show All WebApplication #2'
        get_web_application_with_phisycal_path("def_val")
        } '3' {
          'backup WebApplication. #3'
          $WebApplicationName = Read-Host "Please enter WebApplication name to backup"
          backup_application($WebApplicationName)
        }
        '4' {
          'You chose option #3'
          $application_pool_Nane = Read-Host "Please enter application pool name"
          start_app_pool("$application_pool_Nane")
        }
        '5' {
          'You chose option #3'
          get-app-pools("Started")
        }
        '6' {
          'You chose option #3'
          get-app-pools("Started")
        }
        '7' {
          'You chose option #3'
          get-app-pools("Started")
        }
        'm' {
          main-Menu
        }
        's' {
          server-menu
        }
        }
        pause
     }
     until ($selection -eq 'q')

 }

 function main-Menu {
     
     param (
         [string]$Title = 'main-menu'
     )
     
     Clear-Host
     write-host "server name is: $global:serverName"
     Write-Host "================ $Title ================"
     
     Write-Host "1: Press '1' for application pools menu."
     Write-Host "2: Press '2' for web application menu."
     Write-Host "Q: Press 'Q' to quit."

     $selection = Read-Host "Please make a selection"
     do
     {
        switch ($selection)
        {
        '1' {
        'You chose option #1'
        application-pool-Menu
     
        } '2' {
        'You chose option #2'
        web-site-Menu
        } 's' {
          
         
          server-menu
          
        }
        'm' {
          'You chose option #3'
        }
        'q' {
          'You chose option #q'
          write-host "--------------------------Finish--------------------------------"
          exit 
        }
        }
        pause
     }
     until ($selection -eq 'q')

 }



 function server-menu {
     
     param (
         [string]$Title = 'server-menu'
     )
     
     Clear-Host
     
  Write-Host "1: Press '1' idev20161."
  Write-Host "1: Press '1' idev20161."
  Write-Host "2: Press '2' idev2012."
  Write-Host "3: Press '3' itest20121."
  Write-Host "4: Press '4' itest20161."
  Write-Host "5: Press '5' iprod20121."
  Write-Host "6: Press '6' iprod20122."
  Write-Host "7: Press '7' iprod20165."
  Write-Host "8: Press '8' iprod20166."
  #Write-Host "9: Press '9' 172.19.217.13."
  Write-Host "`nYou can change server any time`n"
  $serverNameSelection = Read-Host "Please choose server"

	   switch ($serverNameSelection)
  {
  '1' {
    Write-Host "hello"
       $global:serverName = "idev20161"
       write-host "Server name change to: $global:serverName"
       
  } '2' {
     $global:serverName = "idev2012"
     write-host "Server name change to: $global:serverName"
  }
  '3' {
   $global:serverName = "itest20121"
   write-host "Server name change to: $global:serverName"
 }
 '4' {
   $global:serverName = "itest20161"
   write-host "Server name change to: $global:serverName"
 }
 '5' {
   $global:serverName = "iprod20121"
   write-host "Server name change to: $global:serverName"
 }
 '6' {
   $global:serverName = "iprod20122"
   write-host "Server name change to: $global:serverName"
 }
 '7' {
   $global:serverName = "iprod20165"
   write-host "Server name change to: $global:serverName"
 }
 '8' {
  $global:serverName = "iprod20166"
  write-host "Server name change to: $global:serverName"
}
'9' {
  $global:serverName = "172.19.217.13"
  write-host "Server name change to: $global:serverName"
}
 
'q' {
  write-host "--------------------------Finish--------------------------------"
    exit 
}
 }

   

 }

 
 function serverMenuFunction() {
     
  param (
      [string]$Title = 'server-menu'
  )
  
Write-Host "1: Press '1' idev20161 ==========================."
Write-Host "2: Press '2' idev2012."
Write-Host "3: Press '3' itest20121."
Write-Host "4: Press '4' itest20161."
Write-Host "5: Press '5' iprod20121."
Write-Host "6: Press '6' iprod20122."
Write-Host "7: Press '7' iprod20165."
Write-Host "8: Press '8' iprod20166."
#Write-Host "9: Press '9' 172.19.217.13."
Write-Host "`nYou can change server any time`n"
$serverNameSelection = Read-Host "Please choose server"
  do
  {
  switch ($serverNameSelection)
{
'1' {
    $global:serverName = "idev20161"
    write-host "Server name change to: $global:serverName"
} '2' {
  $global:serverName = "idev2012"
  write-host "Server name change to: $global:serverName"
}
'3' {
$global:serverName = "itest20121"
write-host "Server name change to: $global:serverName"
}
'4' {
$global:serverName = "itest20161"
write-host "Server name change to: $global:serverName"
}
'5' {
$global:serverName = "iprod20121"
write-host "Server name change to: $global:serverName"
}
'6' {
$global:serverName = "iprod20122"
write-host "Server name change to: $global:serverName"
}
'7' {
$global:serverName = "iprod20165"
write-host "Server name change to: $global:serverName"
}
'8' {
$global:serverName = "iprod20166"
write-host "Server name change to: $global:serverName"
}
'9' {
$global:serverName = "172.19.217.13"
write-host "Server name change to: $global:serverName"
}
'm' {
main-menu
}
'q' {
write-host "--------------------------Finish--------------------------------"
 exit 
}
}

     
  }
  until ($selection -eq 'q')

}



 function selectServer()
 {
  Write-Host "selectServer started"

  
  Write-Host ""
  Write-Host "1: Press '1' idev20161."
  Write-Host "2: Press '2' idev2012."
  Write-Host "3: Press '3' itest20121."
  Write-Host "4: Press '4' itest20161."
  Write-Host "5: Press '5' iprod20121."
  Write-Host "6: Press '6' iprod20122."
  Write-Host "7: Press '7' iprod20165."
  Write-Host "8: Press '8' iprod20166."
  #Write-Host "9: Press '9' 172.19.217.13."
  Write-Host "`nYou can change server any time`n"
  $serverNameSelection = Read-Host "Please choose server"
  
  switch ($serverNameSelection)
  {
  '1' {
       $global:serverName = "idev20161"
       write-host "Server name change to: $global:serverName"
       exit
  } '2' {
     $global:serverName = "idev2012"
     write-host "Server name change to: $global:serverName"
  }
  '3' {
   $global:serverName = "itest20121"
   write-host "Server name change to: $global:serverName"
 }
 '4' {
   $global:serverName = "itest20161"
   write-host "Server name change to: $global:serverName"
 }
 '5' {
   $global:serverName = "iprod20121"
   write-host "Server name change to: $global:serverName"
 }
 '6' {
   $global:serverName = "iprod20122"
   write-host "Server name change to: $global:serverName"
 }
 '7' {
   $global:serverName = "iprod20165"
   write-host "Server name change to: $global:serverName"
 }
 '8' {
  $global:serverName = "iprod20166"
  write-host "Server name change to: $global:serverName"
}
'9' {
  $global:serverName = "172.19.217.13"
  write-host "Server name change to: $global:serverName"
}
 'm' {
  main-menu
}
'q' {
  write-host "--------------------------Finish--------------------------------"
    exit 
}
 }


 Write-Host "selectServer finished"


}



function select-server-on-start()
{
  Write-Host "Please choose server to continue.`n"
  Write-Host "1: Press '1' idev20161."
  Write-Host "1: Press '1' idev20161 ."
  Write-Host "2: Press '2' idev2012."
  Write-Host "3: Press '3' itest20121."
  Write-Host "4: Press '4' itest20161."
  Write-Host "5: Press '5' iprod20121."
  Write-Host "6: Press '6' iprod20122."
  Write-Host "7: Press '7' iprod20165."
  Write-Host "8: Press '8' iprod20166."
  #Write-Host "9: Press '9' 172.19.217.13."
  Write-Host "`nYou can change server any time`n"
  $serverNameSelection = Read-Host "Please choose server"

	   switch ($serverNameSelection)
  {
  '1' {
    Write-Host "hello"
       $global:serverName = "idev20161"
       write-host "Server name change to: $global:serverName"
       
  } '2' {
     $global:serverName = "idev2012"
     write-host "Server name change to: $global:serverName"
  }
  '3' {
   $global:serverName = "itest20121"
   write-host "Server name change to: $global:serverName"
 }
 '4' {
   $global:serverName = "itest20161"
   write-host "Server name change to: $global:serverName"
 }
 '5' {
   $global:serverName = "iprod20121"
   write-host "Server name change to: $global:serverName"
 }
 '6' {
   $global:serverName = "iprod20122"
   write-host "Server name change to: $global:serverName"
 }
 '7' {
   $global:serverName = "iprod20165"
   write-host "Server name change to: $global:serverName"
 }
 '8' {
  $global:serverName = "iprod20166"
  write-host "Server name change to: $global:serverName"
}
'9' {
  $global:serverName = "172.19.217.13"
  write-host "Server name change to: $global:serverName"
}
 
'q' {
  write-host "--------------------------Finish--------------------------------"
    exit 
}
 }




}

$S = 0x1f600
$S = $S - 0x10000
$H = 0xD800 + ($S -shr 10)
$L = 0xDC00 + ($S -band 0x3FF)
$emoji = [char]$H + [char]$L


Write-Host "`nWellcome to Web System IIS CLI tool $emoji"


select-server-on-start


main-Menu 





write-host "--------------------------Finish--------------------------------"
