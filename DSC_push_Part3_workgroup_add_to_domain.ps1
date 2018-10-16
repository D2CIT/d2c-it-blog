 #############################################################################################################################
 # NOTE : If no connection could be made to a non domain joined host check if the networkprofile is on private  
 #        If the networkprofile is on public change registry setting below
 #         - "hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" 
 #         - Set value category on 1 ( 0 = public; 1= private ; 2 = domain)
 #############################################################################################################################

 Function Add-HosttoWSMantrustedHosts{

     <#
    .Synopsis
       Add-HosttoWSMantrustedHosts
    .DESCRIPTION
       Add-HosttoWSMantrustedHosts will add a host/ipadres to the WSMan trustedhosts stored in WSMan:\localhost\Client\TrustedHosts
       With the Command clear-Item WSMan:\localhost\Client\TrustedHosts -force you can clean up the trusted hosts
    .EXAMPLE
        $TrustedHost = "191.168.10.2"
        Add-HosttoWSMantrustedHosts -TrustedHost $TrustedHost
    .Note
       Created by Mark vande Waarsenburg (www.D2C-IT.nl)      
    #>

    param(
        # Param help description
        [Parameter(Mandatory=$true)]
        $TrustedHost 
    )

    begin{ 
        #Check Trusted Hosts LIST
        $CurrentTrusted = (get-item WSMan:\localhost\Client\TrustedHosts).Value
        if($CurrentTrusted -like ""){
            Write-host "[note] : Current Trustedhosts : 0" -for Green
        }else{
            Write-host "[note] : Current Trustedhosts : $CurrentTrusted" -for Green
        }
    }#Begin

    Process{
        $paramHash = @{
            path  = "WSMan:\localhost\Client\TrustedHosts"
            Force = $true
        }
        
        if($saved.value){
            #Add to current trustedhost array
            $paramHash.Add("Value","$($Saved.value) , $TrustedHost")
        }else{
            #Add first trusted Host
            $paramHash.Add("Value", $TrustedHost)
        }#EndIf

        Try{
            #Set trusted host to WSMan
            set-item @paramHash
        }catch{
            Write-host "[Error] : Adding the host ($TrustedHost) to wsman trustedhosts" -for Red
            Break
                }#EndTryCatch
    }#Process

    End{          
        #Check Trusted Hosts LIST
        Write-host "[note] : Current Trustedhosts : $((get-item WSMan:\localhost\Client\TrustedHosts).Value)" -for Green
    }#End

 }#End Function

# Add Remote host to wsman trustedhosts
  $TrustedHost = "192.168.16.128"
  Add-HosttoWSMantrustedHosts -TrustedHost $TrustedHost

# Local credentials of remote host
  $LocalCred =  Get-Credential -username administrator -message "Give Username and Password of remote host"
 
# check connection
  test-wsman $TrustedHost

# Create local config directory to store the MOf Files
  $DCS_Config = "C:\dsc\Config" 
  if(!(test-path $DCS_Config)){mkdir $DCS_Config}

# Start Cimssesion to remote host
  $Cimsession = New-CimSession -ComputerName $trustedhost -Credential $LocalCred 
  Get-DscLocalConfigurationManager -CimSession $Cimsession  | select PSComputerName,RefreshMode,ConfigurationModeFrequencyMins,ConfigurationMode
 
 # Set Domain Credentials
  $username = "d2cit\administrator"
  If(!$DomainCredential){
      $DomainCredential = Get-Credential -UserName $username -Message "Please enter password for Domain Admin account." 
  }#EndiF
 
# DSC Configuration
  Configuration ConfigureHost   {

    import-DscResource -ModuleName xComputerManagement
    node localhost {

        # Create File Structure
        File Scripts    {
            Type            = 'Directory'
            DestinationPath = "C:\Scripts\DSC"
            Ensure          = 'present'
        }
        File DSC        {
            Type            = 'Directory'
            DestinationPath = "C:\Scripts\DSC"
            Ensure          = 'present'
            DependsOn       = "[file]Scripts" 
        }
        
      
        xComputer AddtoDomain {
            Name        = $node.ComputerName  
            DomainName  = $node.domainname
            Credential  = $DomainCredential
            DependsOn   = "[xDnsServerAddress]PrimaryDNSClient"
            JoinOU      = $node.joinOU
            Description = $node.Description
        }
        
 
    }
 }#EndConfiguration
# Parameters 
  $ConfigData = @{
    AllNodes = @(
        @{
            Nodename                    = "localhost"
            ComputerName                = "LABMS01"
            Description                 = "Server 2016"
            JoinOU                      = "OU=Computers,ou=D2C,DC=d2cit,dc=it"
            DomainName                  = "d2cit.it"
            IPAddress                   = "192.168.16.150/24"
            DnsIpAddress                = "192.168.16.140","192.168.16.2"
            GatewayAddress              = "192.168.16.2"
            InterfaceAlias              = "Ethernet0"
            IPDomainController          = "192.168.16.140"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }
    )#AllNodes
  }#ConfigData


# Create MOF
  $computername = $TrustedHost
  ConfigureHost -OutputPath c:\DSC\Config -ConfigurationData $ConfigData
  

# RUN DSC    
  Start-DscConfiguration -Path C:\DSC\Config -ComputerName 192.168.16.128 -Verbose -Wait -Credential $LocalCred


# remove host from  wsman trustedhosts
  clear-Item WSMan:localhost\Client\TrustedHosts -force