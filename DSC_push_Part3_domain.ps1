


# Local credentials of remote host
  $DomainCred =  Get-Credential -username d2cit\administrator -message "Give Username and Password of domain account"
 
# check WSMAN connection
  test-wsman $TrustedHost

# Create local config directory to store the MOf Files
  $DCS_Config = "C:\dsc\Config" 
  if(!(test-path $DCS_Config)){mkdir $DCS_Config}

# Start Cimssesion to remote host
  $Cimsession = New-CimSession -ComputerName $trustedhost -Credential $LocalCred 
  Get-DscLocalConfigurationManager -CimSession $Cimsession  | select PSComputerName,RefreshMode,ConfigurationModeFrequencyMins,ConfigurationMode
 

 # DSC Configuration
 Configuration ConfigureHost  {
    
    node $ComputerName {

        # Create File Structure
        File Scripts    {
            Type            = 'Directory'
            DestinationPath = "C:\Scripts\DSC"
            Ensure          = 'present'
        }
        File DSC    {
            Type            = 'Directory'
            DestinationPath = "C:\Scripts\DSC"
            Ensure          = 'present'
            DependsOn       = "[file]Scripts" 
        }

    }

 }#EndConfiguration

# Create MOF
  $computername = "labms01"
  ConfigureHost -OutputPath c:\DSC\Config

  
# Check if remote dir already exists
  invoke-command -ComputerName $computername -ScriptBlock { test-path C:\Scripts\DSC } -credential $DomainCred -verbose
# RUN DSC    
  Start-DscConfiguration -Path C:\DSC\Config -ComputerName 192.168.16.128 -Verbose -Wait 
# Check again if remote dir already exists
  invoke-command -ComputerName $computername -ScriptBlock { test-path C:\Scripts\DSC } -credential $DomainCred -verbose

