# Intune Proactive Remediations
Here you will find some of the useful proactive remediations I am using

## User Appx Package Management
<p>
<a href="https://github.com/neckermann/ModernDeviceManagement/tree/main/Proactive%20Remediations\UserAppxPackageManagement-Detection.ps1" target="_blank" rel="noopener noreferrer">UserAppxPackageManagement-Detection.ps1</a>
<br>
<a href="https://github.com/neckermann/ModernDeviceManagement/tree/main/Proactive%20Remediations\UserAppxPackageManagement-Remediation.ps1" target="_blank" rel="noopener noreferrer">UserAppxPackageManagement-Remediation.ps1</a>
<br>
</p>
<p>
These 2 files make up the Proactive Remedation used for removing Appx packages from a user. This allows you to create a list of Appx packages that should not be installed for the user. This does not remove the Appx provisioning package which will make it easier to restore if the organization decides to open the application back up to users later. I haven't worked through the add back option yet but once it is a requirement for me I will work on adding it. There is some local logging as well for troubleshooting.
</p>
<p>You would run this in the user context.
<br>
Please modify the list of applications in the UserAppxPackageManagement-Detection.ps1 and UserAppxPackageManagement-Remediation.ps1 $AppxPackagesToRemove list. You can get the list of applications by running this on your image. Get-AppxPackage
