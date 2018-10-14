##########################################################################                                  
# Mark van de Waarsenburg 
# Kijk voor meer blogs op : www.D2C-IT.nl/blog
##########################################################################  


 ##########################################################################
 # Prepare Host
 ##########################################################################
  Function  prep_HostforDSC {
    Param(
        #create directory to store mof file
        $DscDir = "C:\DSC"
    )

    If(!(test-path $DscDir)){ mkdir $DscDir }

    # SETUP PACKAGE PROVIDER
    If( get-PackageProvider | where {$_.name -like "nuget"}){
        Write-host "[Note] : PackageProvider Nuget is installed"  -for Green
    }Else{
        Write-host "[Note] : Could not find PackageProvider Nuget and will be installed"  -for Yellow
        # Setup packageSource
        Get-PackageSource -name PSGallery | set-PackageSource -trusted -Force -ForceBootstrap | out-null
        Install-PackageProvider -name NuGet -force -Confirm:$false| out-null
    }#EndIF

    # IMPORT DSC RESOURCES
    write-host "[Note] : Install Powershell Modules for DSC" -for Yellow
    $modules = @("xComputerManagement","xNetworking" )
    Foreach($Module in $modules){
        write-host "         - Module $module " -for Yellow
        Install-Module -Name $Module 
    }
    ##########################################################################
 } #End function

 # Set Outputpath MOf Files
   $DscDir = "C:\DSC"
 # create directory to store mof file
   prep_HostforDSC -DscDir "C:\DSC"


 ##########################################################################
 # Simpel DSC Configuration
 ##########################################################################

 #Set Domain Credentials
$username = "d2cit\administrator"
If(!$DomainCredential){
    $DomainCredential = Get-Credential -UserName $username -Message "Please enter password for Domain Admin account." 
}#EndiF

# DSC Configuration
 Configuration ConfigureHost  {

    import-DscResource -ModuleName xComputerManagement, XNetworking  
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

        xIPAddress NewIPAddress {
            IPAddress      = $node.IPAddress
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily = 'IPV4'
            DependsOn      = '[xHostsFile]d2cit'
        }
        xDefaultGatewayAddress NewIPGateway {
            Address = $node.GatewayAddress
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = "IPV4"
            DependsOn      = '[xIPAddress]NewIPAddress'
        }
        xDnsServerAddress PrimaryDNSClient  {
            Address        = $node.DNSIPAddress
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = "IPV4"
            DependsOn      = '[xDefaultGatewayAddress]NewIPGateway'
        }

        xHostsFile d2cit       {
            HostName  = "d2cit"
            IPAddress = $node.IPDomainController
            Ensure    = "present"         
        }
        xHostsFile d2citit    {
            HostName  = "d2cit.it"
            IPAddress =  $node.IPDomainController
            Ensure    = "present"          
        }
        xComputer AddtoDomain {
            Name        = $node.ComputerName  
            DomainName  = $node.domainname
            Credential  = $DomainCredential
            DependsOn   = "[xDnsServerAddress]PrimaryDNSClient"
            JoinOU      = $node.joinOU
            Description = $node.Description
        }
        
        xVirtualMemory adjustVirtualMemory {
            Drive = "c:"
            InitialSize = 1000
            MaximumSize = 2000
            Type = 'AutoManagePagingFile'          
        
        }
        Service wuauserv {
            Name  = 'wuauserv'
            State = 'Running'
        }  
    }
 }#EndConfiguration

 #Parameters 
 $ConfigData = @{
    AllNodes = @(
        @{
            Nodename                    = "localhost"
            ComputerName                = "WIN-HCSN4SF4MKA"
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
  ConfigureHost -OutputPath $DscDir -ConfigurationData $ConfigData

# Process mof file on server
  Start-DscConfiguration -path $DscDir -wait -verbose -force



