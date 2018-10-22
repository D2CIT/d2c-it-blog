##########################################################################                                  
# Author : D2C-IT : Mark van de Waarsenburg 
#          Kijk voor meer blogs op : www.D2C-IT.nl/blog
##########################################################################  

# Variables
  $computername = "labw001-sql01"
  $outputPath   = "c:\DSC\Config" 

# Check wsman connection to remote host
  If (!(Test-wsman -ComputerName $computername)){
    Write-warning "Error testing wsman connection to $computername. Script will stop!!" 
    Break
  }

# Check if Feature is installed 
  invoke-command -ComputerName $computername -ScriptBlock {Get-WindowsFeature -name Failover-clustering | select PSComputerName,name,installed}

# DSC Congiguration
  configuration ConfigName {
    Node $ComputerName {
        WindowsFeature AddFailoverFeature{
            Ensure = 'Present'
            Name   = 'Failover-clustering'
        }
    }
  }#EndConfig

# Create MOF Files
  ConfigName -OutputPath $outputPath 

# Process mof file on server
  Start-DscConfiguration -path $outputPath  -ComputerName $computername -wait -verbose -force

# Check if remote host need a reboot
  $Cimsession = New-CimSession -ComputerName $computername
  $DSCStatus  = Get-DscConfigurationStatus -CimSession $Cimsession
  if($DSCStatus.RebootRequested -eq $true){
    Write-warning "Reboot host $computername"; 
    Restart-Computer -ComputerName $computername -Force -AsJob | Wait-job
  }

# Check again if Feature is installed
  invoke-command -ComputerName $computername -ScriptBlock {Get-WindowsFeature -name Failover-clustering |  select PSComputerName,name,installed}