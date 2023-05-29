Import-Module IISAdministration -Verbose:$false
import-module WebAdministration
function Print-Table([Array[]]$_results) {

     

     $testArray = New-Object System.Collections.Generic.List[System.Object]


     foreach ($item in $_results) {
     
          $tmpArray = New-Object System.Collections.Generic.List[System.Object]
      
          $tmpArray.Add(($item.Name,$item.State, $item.PSComputerName))
          
          $testArray+=$tmpArray
      
          $appPool = $item.Name
      
          $status = $item.State
      
          $PSComputerName = $item.PSComputerName
      
      
         # write-host "Name:$appPool          Status.:$status            PSComputerName :$PSComputerName"
      
      } 


      foreach ($currentItemName in $testArray) {
          write-host "in function loop"
          write-host $currentItemName[1]
     }



 }

 function Print-Table-butify([Array[]]$_results) {

     write-host "Print-Table-butify started"

     $tableArray = New-Object System.Collections.Generic.List[System.Object]

     foreach ($item in $_results) {

          $tmpArray = New-Object System.Collections.Generic.List[System.Object]

          $tmpArray.Add(($item.Name,$item.State, $item.PSComputerName))

          $tableArray+=[pscustomobject]@{Name = $item.Name; State = $item.State; PSComputerName =$item.PSComputerName}
    
     } 

     $tableArray | Format-Table
 }


 function get-app-pools([string]$_state) {

     if($_state -EQ "All") {

          $resultsa = Invoke-Command -ComputerName idev20161 { 
               param($_state) 
               Get-IISAppPool 
          } -argumentlist $_state

          
       }else {
          $resultsa = Invoke-Command -ComputerName idev20161 { 
               param($_state) 
               Get-IISAppPool | Where-Object -FilterScript {$_.State -EQ "$_state"}
          } -argumentlist $_state

       }
     
     write-host "Function get-app-pool - start, parameter is: $_state"
     return $resultsa

 }


$results = get-app-pools("All")


Print-Table($results)


Print-Table-butify($results)



write-host "--------------------------Finish--------------------------------"
