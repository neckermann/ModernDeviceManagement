# Intune Custom Compliance
Here you will find some of the useful custom compliance items I am using<br>
Learn about Intune Custom Compliance: https://learn.microsoft.com/en-us/mem/intune/protect/compliance-use-custom-settings<br>

## BIOS Version Custom Compliance
<p>
<a href="https://github.com/neckermann/ModernDeviceManagement/blob/main/Custom%20Compliance/Get-BIOSUpateStatus.ps1" target="_blank" rel="noopener noreferrer">Get-BIOSUpdateStatus.ps1</a>
<br>
<a href="https://github.com/neckermann/ModernDeviceManagement/blob/main/Custom%20Compliance/Get-BIOSUpateStatus.json" target="_blank" rel="noopener noreferrer">Get-BIOSUpdateStatus.json</a>
<br>
</p>
<p>
These 2 files make up the custom compliance script and json to allow you to mark devices non compliant in Intune if they are not on an approved bios version. Using a N and N-1 in the code you can specify them to be at least on x version or x version.
</p>
<p>You should update the model and version info in the Get-BiosUpdateStatus.ps1 to account for your models and versions. You can also update the Get-BIOSUpdateStatus.json MoreInfoUrl with a custom url to link to a KB arcticle on how they can update their BIOS if out of compliance. Such as contact the service desk to find out why the device isn't updating according to policy.
<br>
You would have to rework it a little to support Lenovo models since they use a different class value type in the CIMInstance command.
</p>


## Windows Hello for Business Enrollment Compliance
<p>
<a href="https://github.com/neckermann/ModernDeviceManagement/blob/main/Custom%20Compliance/Get-WindowsHelloStatus.ps1" target="_blank" rel="noopener noreferrer">Get-WindowsHelloStatus.ps1</a>
<br>
<a href="https://github.com/neckermann/ModernDeviceManagement/blob/main/Custom%20Compliance/Get-WindowsHelloStatus.json" target="_blank" rel="noopener noreferrer">Get-WindowsHelloStatus.json</a>
<br>
</p>
<p>
These 2 files make up the custom compliance script and json to allow you to mark devices non compliant in Intune that are not enrolled in Windows Hello for Business. I have added some local logging for troubleshooting.
</p>
<p>Modified version of Martin Bengtsson: https://www.imab.dk/use-custom-compliance-settings-in-microsoft-intune-to-require-windows-hello-enrollment
</p>


