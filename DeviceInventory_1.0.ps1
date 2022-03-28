<#
.SYNOPSIS
	Computer Inventory output as a JSON object.
.DESCRIPTION
	Script that captures Inventory of a COmputer 
.INPUTS
	## To Be added is a configuration section to Specify a SiteName/CompanyCode
	## Add telemtry
.OUTPUTS
	##
.NOTES
	Version:		1.0
	Author:			Kris Wong
	Creation Date:	2021-02-17
	Purpose/Change:	Initial script development
#>

Function Get-Inventory {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True)]
    [string[]]$Computers
  )    

  $Result = [Collections.ArrayList]@() 

  $liveComputers = [Collections.ArrayList]@()
  foreach ($computer in $computers) {
    if (Test-Connection -ComputerName $computer -Quiet -count 1) {
      $null = $liveComputers.Add($computer)
    }
    else {
      Write-Verbose -Message ('{0} is unreachable' -f $computer) -Verbose
    }
  }

  $liveComputers | ForEach-Object {
[Microsoft.Management.Infrastructure.CimCmdlets.ProtocolType]$Protocol = 'DCOM'
$option = New-CimSessionOption -Protocol $protocol
$session = New-CimSession -ComputerName $_ -SessionOption $option
    $Hardware = Get-CimInstance -CimSession $session -Class Win32_ComputerSystem | Select Name,Domain,Manufacturer,SystemFamily,Model,NumberOfProcessors,NumberOfLogicalProcessors,TotalPhysicalMemory,UserName
    $Serial = Get-CimInstance -CimSession $session -Class Win32_Bios | Select  SerialNumber
	$Os = Get-CimInstance -CimSession $session -Class Win32_OperatingSystem | Select  Caption,Manufacturer,Version,SerialNumber,LastBootUpTime,InstallDate,OSArchitecture,BuildNumber, OSType
    $Adapter = Get-CimInstance -CimSession $session -Class Win32_NetworkAdapterConfiguration  |   Select IPAddress,IPSubnet,DefaultIPGateway,MACAddress,Description | Where-Object { $_.IPAddress -ne $null -and $_.DefaultIPGateway -ne $null} 
    $DriveSpace = Get-CimInstance -CimSession $session -Class Win32_Volume  | Select driveletter,label, @{name='FreeSpaceGB';expression= {'{0:N2}' -f ($_.freespace/1GB)}} 
    $Cpu = Get-CimInstance -CimSession $session -Class Win32_Processor  | Select DeviceID, DataWidth, Description, Name, NumberOfCores, ThreadCount, ProcessorId
	$Software = Get-CimInstance -CimSession $session win32_product | Select Name,SKUNumber,Version,IdentifyingNumber,PackageCode,InstallDate,InstallSource,LocalPackage,PackageCache,PackageName

  $Inventory 				= [pscustomobject]@{
		Hardware 			 = $Hardware
		Serial 				 = $Serial
		OS 					 = $Os
 		Adapter 			 = $Adapter
		DriveSpace 			 = $DriveSpace
		Cpu		 			 = $Cpu
		Software 			 = $Software  		
	}
    # create new custom object for each inventoried device
    $Result += [PSCustomObject]@{
      ComputerName			= $_.ToUpper()
	  Inventory				= $Inventory
    }
  }


  # Return all your results
  $Result | ConvertTo-Json | Out-File .\Inventory_Test10.json
}