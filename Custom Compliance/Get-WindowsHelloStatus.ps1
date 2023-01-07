<#
.SYNOPSIS
    Custom compliace script to identify if a user is enrolled in Windows Hello for Business
      
.DESCRIPTION
    This script queries the registry in the context of the logged on user. 
    It queries a specific registry value, to determine if a PIN provider is added for the user in question.
    Using a PIN provider is the minimum required in order to use Windows Hello for Business. Orignial script from Martin Begtsson
    but I added some local logging for troubleshooting. Logging gathered with the standard Intune Diagnostic log collection.

.NOTES
    Filename: Get-WindowsHelloStatus.ps1
    Version: 1.0
    Author: Nick Eckermann Modfied from Martin Bengtsson
    Email: nickeckermann@outlook.com
.LINK
    https://github.com/neckermann/ModernDeviceManagement/tree/main/Custom%20Compliance\Get-WindowsHelloStatus.ps1
.LINK
    Modified version of Martin Bengtsson: https://www.imab.dk/use-custom-compliance-settings-in-microsoft-intune-to-require-windows-hello-enrollment
#>

#Loggging
# Logging Path
$LoggingPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\CustomCompliance.log"

# Write-Log Function

function Write-Log {
    <#
        .SYNOPSIS
        Function to write a message to a log file in a CMTrace/OneTrace format.
    
        .DESCRIPTION
        Function to write a message to a log file in a CMTrace/OneTrace format.
        You specifiy the Path to the log file.
        You specify the main Message you want written to the log.
        You specify the Type of logging informational, warning, error.
        You specify the Component you are logging if writing from muliple sources to the same file.
        You specify the number of days to keep the file you are logging to.
    
        .PARAMETER Path
        Location logs should be written to.
    
        .PARAMETER Message
        The message you want to write to the log.
    
        .PARAMETER Type
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
        PS> Write-Log -Message "An error has occured in our script" -Type Error -Component OurScript.ps1 -Path C:\Windows\Temp\MyLogFile.log -LoggingCleanupDays 30
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
              [String]$Type,
              [parameter(Mandatory=$false)]
              [String]$Component,
              [Parameter(Mandatory=$false)]
              [ValidateRange(1,365)]
              [int]$LoggingCleanupDays
        )
        switch ($Type) {
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
        Add-Content -Path $Path -Value $Content -ErrorAction SilentlyContinue
    }

# Get-WindowsHelloStatus Function
function Get-WindowsHelloStatus() {
    # Get currently logged on user's SID
    $currentUserSID = (whoami /user /fo csv | convertfrom-csv).SID
    $currentUser = (whoami /user /fo csv | convertfrom-csv).'User Name'
    # Registry path to credential provider belonging for the PIN. A PIN is required with Windows Hello
    $credentialProvider = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{D6886603-9D2F-4EB2-B667-1971041FA96B}"
    if (Test-Path -Path $credentialProvider) {
        $userSIDs = Get-ChildItem -Path $credentialProvider
        $registryItems = $userSIDs | Foreach-Object { Get-ItemProperty $_.PsPath }
    }
    else {
        Write-Output "Not able to determine Windows Hello enrollment status"
        Write-Log -Message "Not able to determine Windows Hello enrollment status" `
                  -Path $LoggingPath `
                  -Component Get-WindowsHelloStatus.ps1 `
                  -LoggingCleanupDays 30 `
                  -Type Warning
        Exit 1
    }
    if(-NOT[string]::IsNullOrEmpty($currentUserSID)) {
        # If multiple SID's are found in registry, look for the SID belonging to the logged on user
        if ($registryItems.GetType().IsArray) {
            # LogonCredsAvailable needs to be set to 1, indicating that the PIN credential provider is in use
            if ($registryItems.Where({$_.PSChildName -eq $currentUserSID}).LogonCredsAvailable -eq 1) {
                Write-Output "ENROLLED"
                Write-Log -Message "$currentUser is enrolled in Windows Hello for Business" `
                          -Path $LoggingPath `
                          -Component Get-WindowsHelloStatus.ps1 `
                          -LoggingCleanupDays 30 `
                          -Type Informational     
            }
            else {
                Write-Output "NOTENROLLED"
                Write-Log -Message "$currentUser is NOT enrolled in Windows Hello for Business" `
                          -Path $LoggingPath `
                          -Component Get-WindowsHelloStatus.ps1 `
                          -LoggingCleanupDays 30 `
                          -Type Warning
            }
        }
        else {
            if (($registryItems.PSChildName -eq $currentUserSID) -AND ($registryItems.LogonCredsAvailable -eq 1)) {
                Write-Output "ENROLLED"
                Write-Log -Message "$currentUser is enrolled in Windows Hello for Business" `
                          -Path $LoggingPath `
                          -Component Get-WindowsHelloStatus.ps1 `
                          -LoggingCleanupDays 30 `
                          -Type Informational
            }
            else {
                Write-Output "NOTENROLLED"
                Write-Log -Message "$currentUser is not enrolled in Windows Hello for Business" `
                          -Path $LoggingPath `
                          -Component Get-WindowsHelloStatus.ps1 `
                          -LoggingCleanupDays 30 `
                          -Type Warning
            } 
        }
    }
    else {
        Write-Output "Not able to determine Windows Hello enrollment status"
        Write-Log -Message "Not able to determine Windows Hello enrollment status" `
                  -Path $LoggingPath `
                  -Component Get-WindowsHelloStatus.ps1 `
                  -LoggingCleanupDays 30 `
                  -Type Warning
        Exit 1
    }
}

# Return Windows Hello status to Intune in JSON format
$WHfB = Get-WindowsHelloStatus
$hash = @{EnrollmentStatus = $WHfB}
return $hash | ConvertTo-Json -Compress