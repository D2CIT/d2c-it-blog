##########################################################################                                  
# Mark van de Waarsenburg 
# Kijk voor meer blogs op : www.D2C-IT.nl/blog
##########################################################################  


##########################################################################
# Simpel DSC Configuration
##########################################################################

#create directory to store mof file
$DscDir = "C:\DSC"
If(!(test-path $DscDir)){ mkdir $DscDir }
#Set location to $DscDir
Set-location $DscDir



# DSC Configuration
 Configuration ConfigureHost  {
    
    node localhost {

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
 ConfigureHost -OutputPath $DscDir

#Process mof file on server
 Start-DscConfiguration -path $DscDir\ConfigureHost -wait -verbose -force


#Default LCM manager Settings
 $LCM = Get-DscLocalConfigurationManager | 
                select ConfigurationMode,LCMState,RebootNodeIfNeeded,RefreshMode,ConfigurationModeFrequencyMins
 Write-host "DSC RefreshMode frequency is minutes = $($LCM.ConfigurationModeFrequencyMins)" -ForegroundColor Green
 $LCM 