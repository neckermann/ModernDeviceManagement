<#
.SYNOPSIS
    Determine if the bios is on the version we require
      
.DESCRIPTION
    Determine if the bios is on the version we require

.NOTES
    Filename: Get-BIOSUpdateStatus.ps1
    Version: 1.0
    Author: Nick Eckermann
    Email: nickeckermann@outlook.com
.LINK
     
#> 

#Loggging
# Logging Path
$LoggingPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\CustomCompliance.log"
#Clean up log after 30 days
$LoggingCleanupDays = '30'

# Write-Log Function
function Write-Log {
    <#
        .SYNOPSIS
        Function to write a message to a log file in a CMTrace/OneTrace format.
    
        .DESCRIPTION
        Function to write a message to a log file in a CMTrace/OneTrace format.
        You specifiy the Path to the log file.
        You specify the main Message you want written to the log.
        You specify the Level of logging informational, warning, error.
        You specify the Component you are logging if writing from muliple sources to the same file.
        You specify the number of days to keep the file you are logging to.
    
        .PARAMETER Path
        Location logs should be written to.
    
        .PARAMETER Message
        The message you want to write to the log.
    
        .PARAMETER Level
        The type of message to log, Informational, Warning, Error
    
        .PARAMETER Component
        The componet you are logging for.
    
        .PARAMETER LoggingCleanupDays
        Clean up the log file you are writing to if it is older than X days.
    
        .INPUTS
        None. You cannot pipe objects to Write-Log.
    
        .OUTPUTS
        None. There are no outputs from Write-Log. Content is written to the logging file.
    
        .EXAMPLE
        Example 1
        PS> Write-Log -Message "An error has occured in our script" -Level Error -Component OurScript.ps1 -Path C:\Windows\Temp\MyLogFile.log -LoggingCleanupDays 30
        Data written to log file. If the log file was older than 30 days file was deleted and a new one created with this content.
        <![LOG[An error has occured in our script]LOG]!><time="22:16:47.161412" date="1-6-2023" component="OurScript.ps1" context="NME-MAC-VM\nicke" type="3" thread="13" file="">
    
        .LINK
        Online version: https://github.com/neckermann/ModernDeviceManagement/tree/main/Scripts/Write-Log.ps1
        
        .LINK
        Modified from a version found: https://janikvonrotz.ch/2017/10/26/powershell-logging-in-cmtrace-format/
        
        .NOTES
        Filename: Write-Log.ps1
        Version: 1.0.0
        Author: Nick Eckermann
        Email: nickeckermann@outlook.com
        1.0.0 Nick Eckermann
        Original script
        
    #>
        [CmdletBinding()]
        Param(
              [parameter(Mandatory=$true)]
              [String]$Path,
              [parameter(Mandatory=$true)]
              [String]$Message,
              [Parameter(Mandatory=$true)]
              [ValidateSet("Informational", "Warning", "Error")]
              [String]$Level,
              [parameter(Mandatory=$false)]
              [String]$Component,
              [Parameter(Mandatory=$false)]
              [ValidateRange(1,365)]
              [int]$LoggingCleanupDays
        )
        switch ($Level) {
            "Informational" { [int]$Type = 1 }
            "Warning" { [int]$Type = 2 }
            "Error" { [int]$Type = 3 }
        }
    
        # Check Path exists for log gathering
        if(!(Test-Path -Path $Path)){
            New-Item -Path $Path `
            -ItemType File `
            -Force `
            -ErrorAction SilentlyContinue | `
            Out-Null
        }
    
        # Clean up log if requested
        if($LoggingCleanupDays){
            Get-Item -Path $Path -ErrorAction SilentlyContinue | `
            Where-Object CreationTime -LE (Get-Date).AddDays("-$LoggingCleanupDays") | `
            Remove-Item -Force | `
            Out-Null
        }
    
        # Create a log entry
        $Content = "<![LOG[$Message]LOG]!>" +`
            "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
            "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$Type`" " +`
            "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
            "file=`"`">"
    
        # Write the line to the log file
        Add-Content -Path $Path -Value $Content
    }

# Get-BiosUpdateStatus Function
function Get-BiosUpdateStatus() {

    # HP EliteDesk 800 G5 Desktop Mini Info
    $HP800G5 = 'HP EliteDesk 800 G5 Desktop Mini'
    $HP800G5VersionN = '02.10.01'
    $HP800G5VersionN1 = '02.09.00'

    # HP EliteBook x360 830 G6 Notebook Info
    $HPx360G6 = 'HP EliteBook x360 830 G6'
    $HPx360G6VersionN = '01.10.01'
    $HPx360G6VersionN1 = '01.09.00'

    # HP EliteBook 840 G5 Info
    $HP840G5 = 'HP EliteBook 840 G5'
    $HP840G5VersionN = "01.16.00"
    $HP840G5VersionN1 = "01.15.00"

    #All Models
    $Models = $HP800G5, $HPx360G6, $HP840G5

    # Get Model and BIOS Info
    $ComputerInfo = Get-CimInstance -Class Win32_ComputerSystem
    $BIOSInfo = Get-CimInstance -Class Win32_BIOS

    # Verify it is a supported model
    if ($Models -contains $ComputerInfo.Model){
        #Find model and check if Bios version is N or N-1    
        # HP EliteDesk 800 G5 Desktop Mini PC
        if ($ComputerInfo.Model -like $HP800G5){        
            if (($BIOSInfo.SMBIOSBIOSVersion -like "*$HP800G5VersionN*") -or ($BIOSInfo.SMBIOSBIOSVersion -like "*$HP800G5VersionN1*")) {
                Write-Output -InputObject "UPDATED"
                Write-Log -Message "$env:COMPUTERNAME $($ComputerInfo.Model) BIOS is updated, on version $($BIOSInfo.SMBIOSBIOSVersion)" `
                          -Path $LoggingPath `
                          -LoggingCleanupDays 30 `
                          -Component Get-BIOSUpdateStatus.ps1 `
                          -Level Informational
            }else{
                Write-Output -InputObject "NOTUPDATED"
                Write-Log -Message "$env:COMPUTERNAME $($ComputerInfo.Model) BIOS not updated, on version $($BIOSInfo.SMBIOSBIOSVersion)" `
                          -Path $LoggingPath `
                          -LoggingCleanupDays 30 `
                          -Component Get-BIOSUpdateStatus.ps1 `
                          -Level Warning
            }
        # HP EliteBook x360 830 G6 Notebook PC Info
        }elseif ($ComputerInfo.Model -like $HPx360G6){
            if (($BIOSInfo.SMBIOSBIOSVersion -like "*$HPx360G6VersionN*") -or ($BIOSInfo.SMBIOSBIOSVersion -contains "*$HPx360G6VersionN1*")){
                Write-Output -InputObject "UPDATED"
                Write-Log -Message "$env:COMPUTERNAME $($ComputerInfo.Model) BIOS is updated, on version $($BIOSInfo.SMBIOSBIOSVersion)" `
                -Path $LoggingPath `
                -LoggingCleanupDays 30 `
                -Component Get-BIOSUpdateStatus.ps1 `
                -Level Informational
            }else{
                Write-Output -InputObject "NOTUPDATED"
                Write-Log -Message "$env:COMPUTERNAME $($ComputerInfo.Model) BIOS is not updated, on version $($BIOSInfo.SMBIOSBIOSVersion)" `
                          -Path $LoggingPath `
                          -LoggingCleanupDays 30 `
                          -Component Get-BIOSUpdateStatus.ps1 `
                          -Level Warning
            }
        }elseif ($ComputerInfo.Model -like $HP840G5){
            if (($BIOSInfo.SMBIOSBIOSVersion -like "*$HP840G5VersionN*") -or ($BIOSInfo.SMBIOSBIOSVersion -like "*$HP840G5VersionN1*")){
                Write-Output -InputObject "UPDATED"
                Write-Log -Message "$env:COMPUTERNAME $($ComputerInfo.Model) BIOS is updated, on version $($BIOSInfo.SMBIOSBIOSVersion)" `
                -Path $LoggingPath `
                -LoggingCleanupDays 30 `
                -Component Get-BIOSUpdateStatus.ps1 `
                -Level Informational
            }else{
                Write-Output -InputObject "NOTUPDATED"
                Write-Log -Message "$env:COMPUTERNAME $($ComputerInfo.Model) BIOS is not updated, on version $($BIOSInfo.SMBIOSBIOSVersion)" `
                -Path $LoggingPath `
                -LoggingCleanupDays 30
                -Component Get-BIOSUpdateStatus.ps1 `
                -Level Warning
            }
        }
    }else{
        Write-Output -InputObject "Not able to determine if this model $($ComputerInfo.Model) is in our supported list"
        Write-Log -Message "Not able to determine if this model $($ComputerInfo.Model) is in our supported list" `
        -Path $LoggingPath `
        -LoggingCleanupDays 30 `
        -Component Get-BiosUpdateStatus.ps1 `
        -Level Warning
    }
}

# Return BIOS status to Intune in JSON format
$BIOSStatus = Get-BiosUpdateStatus
$hash = @{BIOSUpdateStatus = $BIOSStatus}
return $hash | ConvertTo-Json -Compress