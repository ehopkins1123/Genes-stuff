param( [parameter(Mandatory=$true)] [int]$MinPri, [parameter(Mandatory=$true)] [int]$MaxPri )

##########################################################
# Constants
##########################################################
Set-Variable vbCrLf     -Option Constant -Value ([char]13 + [char]10)
Set-Variable logName    -Option Constant -Value 'Application'
Set-Variable sourceName -Option Constant -Value 'AlertTest'



##########################################################
# Validate the parameters
##########################################################
$badParams = $true
If ( ($MinPri -eq 3) -and ($MaxPri -eq 3) ) { $badParams = $false }
If ( ($MinPri -eq 4) -and ($MaxPri -eq 4) ) { $badParams = $false }
If ( ($MinPri -eq 4) -and ($MaxPri -eq 3) ) { $badParams = $false }

If ( $badParams ) 
{

  $errMessage = $vbCrLf
  $errMessage = $errMessage + "Unacceptable parameters.  Acceptable parameter combinations are:" + $vbCrLf
  $errMessage = $errMessage + "-MinPri 3 -MaxPri 3" + $vbCrLf
  $errMessage = $errMessage + "-MinPri 4 -MaxPri 4" + $vbCrLf
  $errMessage = $errMessage + "-MinPri 4 -MaxPri 3" + $vbCrLf + $vbCrLf
  $errMessage = $errMessage + "Matching Min and MaxPri parameters will force a Pri 3 or Pri 4 alert" + $vbCrLf
  $errMessage = $errMessage + "without regard to the priority of the server's service catalog." + $vbCrLf + $vbCrLf
  $errMessage = $errMessage + "MaxPri 3 and MinPri 4 will generate a Pri 3 alert which Alert Enhancer" + $vbCrLf
  $errMessage = $errMessage + "may downgrade to the service catalog's priority." + $vbCrLf

  Write-Host $errMessage -ForegroundColor Yellow -BackgroundColor Black

  Exit
}



##########################################################
# Create the event log and source.  Needs to be run as
# an administrator.  We'll catch the error later
# if we try and use a log that doesn't exist.
##########################################################
New-EventLog -LogName $logName -Source $sourceName -ErrorAction SilentlyContinue
If ( $Error.Count -ne 0 )
{
  $Error.Clear()
}



##########################################################
# Construct the event text and event ID
##########################################################
$whoami = [Environment]::UserDomainName + '\' + [Environment]::UserName
$eventText = "A test event designed to generate an alert in SCOM.  Run by: " + $whoami

$eventID = 34
If ( ($MaxPri -eq 3) -and ($MinPri -eq 3) ) { $eventID = 3 }
If ( ($MaxPri -eq 4) -and ($MinPri -eq 4) ) { $eventID = 4 }



##########################################################
# Write the event and handle any errors
##########################################################
Write-EventLog -LogName $logName -Source $sourceName -EntryType Information -Message $eventText -EventId $eventID -ErrorAction SilentlyContinue

If ( $Error.Count -ne 0 )
{
  $eventMessage = $vbCrLf + "Script failure.  Error(s):" + $vbCrLf
  Foreach ($myerr In $Error)
  {
    $eventMessage = $eventMessage + $myerr.ToString() + $vbCrLf
  }
  Write-Host $eventMessage -ForegroundColor Yellow -BackgroundColor Black
}
Else
{
  Write-Host "Success" -ForegroundColor Green -BackgroundColor Black
}
