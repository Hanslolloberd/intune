
<#
.SYNOPSIS
This script imports the PFX certificate, grabs the Autopilot parameters from the JSON file, executes the CustomWindowsAutopilotInfo function, disconnects the Graph API, and removes the scripts.

.NOTES
   Version:			  0.1
   Creation Date:	30.10.2024
   Author:			  Akos Bakos
   Company:			  SmartCon GmbH
   Contact:			  akos.bakos@smartcon.ch

   Copyright (c) 2024 SmartCon GmbH

HISTORY:
Date			By			Comments
----------		---			----------------------------------------------------------
24.11.2024		Akos Bakos	Script created

#>

#region Helper Functions
function Write-DarkGrayDate {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [System.String]
        $Message
    )
    if ($Message) {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $Message"
    }
    else {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
    }
}
function Write-DarkGrayHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [System.String]
        $Message
    )
    Write-Host -ForegroundColor DarkGray $Message
}
function Write-DarkGrayLine {
    [CmdletBinding()]
    param ()
    Write-Host -ForegroundColor DarkGray "========================================================================="
}
function Write-SectionHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [System.String]
        $Message
    )
    Write-DarkGrayLine
    Write-DarkGrayDate
    Write-Host -ForegroundColor Cyan $Message
}
function Write-SectionSuccess {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [System.String]
        $Message = 'Success!'
    )
    Write-DarkGrayDate
    Write-Host -ForegroundColor Green $Message
}
#endregion

$Title = "Autopilot Tasks"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath+";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path+";C:\Program Files\WindowsPowerShell\Scripts"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Autopilot-Tasks.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore | Out-Null

Function CustomWindowsAutopilotInfo {

<#
	.SYNOPSIS
	Retrieves the Windows AutoPilot deployment details from one or more computers
	MIT LICENSE
	Copyright (c) 2023 Microsoft
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	.DESCRIPTION
	This script uses WMI to retrieve properties needed for a customer to register a device with Windows Autopilot.  Note that it is normal for the resulting CSV file to not collect a Windows Product ID (PKID) value since this is not required to register a device.  Only the serial number and hardware hash will be populated.
	.PARAMETER Name
	The names of the computers.  These can be provided via the pipeline (property name Name or one of the available aliases, DNSHostName, ComputerName, and Computer).
	.PARAMETER OutputFile
	The name of the CSV file to be created with the details for the computers.  If not specified, the details will be returned to the PowerShell
	pipeline.
	.PARAMETER Append
	Switch to specify that new computer details should be appended to the specified output file, instead of overwriting the existing file.
	.PARAMETER Credential
	Credentials that should be used when connecting to a remote computer (not supported when gathering details from the local computer).
	.PARAMETER Partner
	Switch to specify that the created CSV file should use the schema for Partner Center (using serial number, make, and model).
	.PARAMETER GroupTag
	An optional tag value that should be included in a CSV file that is intended to be uploaded via Intune (not supported by Partner Center or Microsoft Store for Business).
	.PARAMETER AssignedUser
	An optional value specifying the UPN of the user to be assigned to the device.  This can only be specified for Intune (not supported by Partner Center or Microsoft Store for Business).
	.PARAMETER Online
	Add computers to Windows Autopilot via the Intune Graph API
	.PARAMETER AssignedComputerName
	An optional value specifying the computer name to be assigned to the device.  This can only be specified with the -Online switch and only works with AAD join scenarios.
	.PARAMETER AddToGroup
	Specifies the name of the Azure AD group that the new device should be added to.
	.PARAMETER Assign
	Wait for the Autopilot profile assignment.  (This can take a while for dynamic groups.)
	.PARAMETER Reboot
	Reboot the device after the Autopilot profile has been assigned (necessary to download the profile and apply the computer name, if specified).
	.EXAMPLE
	.\Get-WindowsAutoPilotInfo.ps1 -ComputerName MYCOMPUTER -OutputFile .\MyComputer.csv
	.EXAMPLE
	.\Get-WindowsAutoPilotInfo.ps1 -ComputerName MYCOMPUTER -OutputFile .\MyComputer.csv -GroupTag Kiosk
	.EXAMPLE
	.\Get-WindowsAutoPilotInfo.ps1 -ComputerName MYCOMPUTER -OutputFile .\MyComputer.csv -GroupTag Kiosk -AssignedUser JohnDoe@contoso.com
	.EXAMPLE
	.\Get-WindowsAutoPilotInfo.ps1 -ComputerName MYCOMPUTER -OutputFile .\MyComputer.csv -Append
	.EXAMPLE
	.\Get-WindowsAutoPilotInfo.ps1 -ComputerName MYCOMPUTER1,MYCOMPUTER2 -OutputFile .\MyComputers.csv
	.EXAMPLE
	Get-ADComputer -Filter * | .\GetWindowsAutoPilotInfo.ps1 -OutputFile .\MyComputers.csv
	.EXAMPLE
	Get-CMCollectionMember -CollectionName "All Systems" | .\GetWindowsAutoPilotInfo.ps1 -OutputFile .\MyComputers.csv
	.EXAMPLE
	.\Get-WindowsAutoPilotInfo.ps1 -ComputerName MYCOMPUTER1,MYCOMPUTER2 -OutputFile .\MyComputers.csv -Partner
	.EXAMPLE
	.\GetWindowsAutoPilotInfo.ps1 -Online

#>

[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, Position = 0)][alias("DNSHostName", "ComputerName", "Computer")] [String[]] $Name = @("localhost"),
    [Parameter(Mandatory = $False)] [String] $OutputFile = "", 
    [Parameter(Mandatory = $False)] [String] $InputFile = "", 
    [Parameter(Mandatory = $False)] [Switch] $identifier = $false, 
    [Parameter(Mandatory = $False)] [String] $GroupTag = "",
    [Parameter(Mandatory = $False)] [String] $AssignedUser = "",
    [Parameter(Mandatory = $False)] [Switch] $Append = $false,
    [Parameter(Mandatory = $False)] [System.Management.Automation.PSCredential] $Credential = $null,
    [Parameter(Mandatory = $False)] [Switch] $Partner = $false,
    [Parameter(Mandatory = $False)] [Switch] $Force = $false,
    [Parameter(Mandatory = $True, ParameterSetName = 'Online')] [Switch] $Online = $false,
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [String] $TenantId = "",
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [String] $AppId = "",
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [String] $AppSecret = "",
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [String] $CertificateSubjectName = "",
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [String] $CertificateThumbprint = "",
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [String[]] $AddToGroup = "",
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [String] $AssignedComputerName = "",
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [Switch] $Assign = $false, 
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [Switch] $Reboot = $false,
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [Switch] $Wipe = $false,
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [Switch] $Sysprep = $false,
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [Switch] $preprov = $false,
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [Switch] $delete = $false,
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [Switch] $updatetag = $false,
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [Switch] $newdevice = $false,
    [Parameter(Mandatory = $False, ParameterSetName = 'Online')] [String] $ChangePK = ""
)

Begin {
    # Initialize empty list
    $computers = @()

    # If online, make sure we are able to authenticate
    if ($Online) {

        # Get NuGet
        $provider = Get-PackageProvider NuGet -ErrorAction Ignore
        if (-not $provider) {
            Write-Host "Installing provider NuGet"
            Find-PackageProvider -Name NuGet -ForceBootstrap -IncludeDependencies
        }
        
        # Get Graph Authentication module (and dependencies)
        $module = Import-Module microsoft.graph.authentication -PassThru -ErrorAction Ignore
        if (-not $module) {
            Write-Host "Installing module microsoft.graph.authentication"
            Install-Module microsoft.graph.authentication -Force -ErrorAction Ignore -MaximumVersion 2.9.1
        }
        #Import-Module microsoft.graph.authentication -Scope Global

        # Get Microsoft Graph Groups if needed
        if ($AddToGroup) {
            $module = Import-Module microsoft.graph.groups -PassThru -ErrorAction Ignore
            if (-not $module) {
                Write-Host "Installing module MS Graph Groups"
                Install-Module microsoft.graph.groups -Force -ErrorAction Ignore
            }
            Import-Module microsoft.graph.groups -Scope Global

        }

        $module2 = Import-Module Microsoft.Graph.Identity.DirectoryManagement -PassThru -ErrorAction Ignore
        if (-not $module2) {
            Write-Host "Installing module MS Graph Identity Management"
            Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force -ErrorAction Ignore
        }
        Import-Module microsoft.graph.Identity.DirectoryManagement -Scope Global

        ##Add functions from module
        Function Connect-ToGraph {
            <#
.SYNOPSIS
Authenticates to the Graph API via the Microsoft.Graph.Authentication module.
  
.DESCRIPTION
The Connect-ToGraph cmdlet is a wrapper cmdlet that helps authenticate to the Intune Graph API using the Microsoft.Graph.Authentication module. It leverages an Azure AD app ID and app secret for authentication or user-based auth.
  
.PARAMETER Tenant
Specifies the tenant (e.g. contoso.onmicrosoft.com) to which to authenticate.
  
.PARAMETER AppId
Specifies the Azure AD app ID (GUID) for the application that will be used to authenticate.
  
.PARAMETER AppSecret
Specifies the Azure AD app secret corresponding to the app ID that will be used to authenticate.
 
.PARAMETER Scopes
Specifies the user scopes for interactive authentication.
  
.EXAMPLE
Connect-ToGraph -Tenant $tenantID -AppId $app -AppSecret $secret
  
-#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $false)] [string]$Tenant,
                [Parameter(Mandatory = $false)] [string]$AppId,
                [Parameter(Mandatory = $false)] [string]$AppSecret,
                [Parameter(Mandatory = $false)] [string]$CertificateSubjectName,
                [Parameter(Mandatory = $false)] [string]$CertificateThumbprint,
                [Parameter(Mandatory = $false)] [string]$scopes
            )

            Process {
                Import-Module Microsoft.Graph.Authentication
                $version = (Get-Module microsoft.graph.authentication | Select-Object -ExpandProperty Version).major

                if ($AppId -ne "") {
                    if ($CertificateThumbprint) {
                        $graph = Connect-MgGraph -CertificateThumbprint $CertificateThumbprint -TenantId $Tenant -AppId $AppId 
                        Write-Host "Connected to Intune tenant $TenantId using certificate thumbprint authentication"
                    }
                    elseif ($CertificateSubjectName) {
                        $graph = Connect-MgGraph -CertificateName $CertificateSubjectName -TenantId $Tenant -AppId $AppId
                        Write-Host "Connected to Intune tenant $TenantId using certificate subject name authentication"
                    }
                    else {

                        $body = @{
                            grant_type    = "client_credentials";
                            client_id     = $AppId;
                            client_secret = $AppSecret;
                            scope         = "https://graph.microsoft.com/.default";
                        }
     
                        $response = Invoke-RestMethod -Method Post -Uri https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token -Body $body
                        $accessToken = $response.access_token
     
                        $accessToken
                        if ($version -eq 2) {
                            Write-Host "Version 2 module detected"
                            $accesstokenfinal = ConvertTo-SecureString -String $accessToken -AsPlainText -Force
                        }
                        else {
                            Write-Host "Version 1 Module Detected"
                            Select-MgProfile -Name Beta
                            $accesstokenfinal = $accessToken
                        }

                        $graph = Connect-MgGraph -AccessToken $accesstokenfinal 
                        Write-Host "Connected to Intune tenant $TenantId using app-based authentication (Azure AD authentication not supported)"
                    }
                }
                else {
                    if ($version -eq 2) {
                        Write-Host "Version 2 module detected"
                    }
                    else {
                        Write-Host "Version 1 Module Detected"
                        Select-MgProfile -Name Beta
                    }
                    $graph = Connect-MgGraph -Scopes $scopes
                    Write-Host "Connected to Intune tenant $($graph.TenantId)"
                }
            }
        }    
        #region Helper methods

        Function BoolToString() {
            param
            (
                [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)] [bool] $value
            )

            Process {
                return $value.ToString().ToLower()
            }
        }

        #endregion



        #region Core methods

        Function Get-AutopilotDevice() {
            <#
.SYNOPSIS
Gets devices currently registered with Windows Autopilot.
  
.DESCRIPTION
The Get-AutopilotDevice cmdlet retrieves either the full list of devices registered with Windows Autopilot for the current Azure AD tenant, or a specific device if the ID of the device is specified.
  
.PARAMETER id
Optionally specifies the ID (GUID) for a specific Windows Autopilot device (which is typically returned after importing a new device)
  
.PARAMETER serial
Optionally specifies the serial number of the specific Windows Autopilot device to retrieve
  
.PARAMETER expand
Expand the properties of the device to include the Autopilot profile information
  
.EXAMPLE
Get a list of all devices registered with Windows Autopilot
  
Get-AutopilotDevice
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)] $id,
                [Parameter(Mandatory = $false)] $serial,
                [Parameter(Mandatory = $false)] [Switch]$expand = $false
            )

            Process {

                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/windowsAutopilotDeviceIdentities"
    
                if ($id -and $expand) {
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$($id)?`$expand=deploymentProfile,intendedDeploymentProfile"
                }
                elseif ($id) {
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$id"
                }
                elseif ($serial) {
                    $encoded = [uri]::EscapeDataString($serial)
                    ##Check if serial contains a space
                    $serialelements = $serial.Split(" ")
                    if ($serialelements.Count -gt 1) {
                        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=contains(serialNumber,'$($serialelements[0])')"
                        $serialhasspaces = 1
                    }
                    else {
                        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=contains(serialNumber,'$encoded')"
                    }
                }
                else {
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                }

                Write-Verbose "GET $uri"

                try {
                    $response = Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject
                    if ($id) {
                        $response
                    }
                    else {
                        if ($serialhasspaces -eq 1) {  
                            $devices = $response.value | Where-Object { $_.serialNumber -eq "$($serial)" }
                        }
                        else {
                            $devices = $response.value 
                        }
                        $devicesNextLink = $response."@odata.nextLink"
    
                        while ($null -ne $devicesNextLink) {
                            $devicesResponse = (Invoke-MgGraphRequest -Uri $devicesNextLink -Method Get -OutputType PSObject)
                            $devicesNextLink = $devicesResponse."@odata.nextLink"
                            if ($serialhasspaces -eq 1) {
                                $devices += $devicesResponse.value | Where-Object { $_.serialNumber -eq "$($serial)" }
                            }
                            else {
                                $devices += $devicesResponse.value
                            }
                        }
    
                        if ($expand) {
                            $devices | Get-AutopilotDevice -expand
                        }
                        else {
                            $devices
                        }
                    }
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }
            }
        }


        Function Set-AutopilotDevice() {
            <#
.SYNOPSIS
Updates settings on an Autopilot device.
  
.DESCRIPTION
The Set-AutopilotDevice cmdlet can be used to change the updatable properties on a Windows Autopilot device object.
  
.PARAMETER id
The Windows Autopilot device id (mandatory).
  
.PARAMETER userPrincipalName
The user principal name.
  
.PARAMETER addressibleUserName
The name to display during Windows Autopilot enrollment. If specified, the userPrincipalName must also be specified.
  
.PARAMETER displayName
The name (computer name) to be assigned to the device when it is deployed via Windows Autopilot. This is presently only supported with Azure AD Join scenarios. Note that names should not exceed 15 characters. After setting the name, you need to initiate a sync (Invoke-AutopilotSync) in order to see the name in the Intune object.
  
.PARAMETER groupTag
The group tag value to set for the device.
  
.EXAMPLE
Assign a user and a name to display during enrollment to a Windows Autopilot device.
  
Set-AutopilotDevice -id $id -userPrincipalName $userPrincipalName -addressableUserName "John Doe" -displayName "CONTOSO-0001" -groupTag "Testing"
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $True)] $id,
                [Parameter(ParameterSetName = "Prop")] $userPrincipalName = $null,
                [Parameter(ParameterSetName = "Prop")] $addressableUserName = $null,
                [Parameter(ParameterSetName = "Prop")][Alias("ComputerName", "CN", "MachineName")] $displayName = $null,
                [Parameter(ParameterSetName = "Prop")] $groupTag = $null
            )

            Process {
    
                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/windowsAutopilotDeviceIdentities"
    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id/UpdateDeviceProperties"

                $json = "{"
                if ($PSBoundParameters.ContainsKey('userPrincipalName')) {
                    $json = $json + " userPrincipalName: `"$userPrincipalName`","
                }
                if ($PSBoundParameters.ContainsKey('addressableUserName')) {
                    $json = $json + " addressableUserName: `"$addressableUserName`","
                }
                if ($PSBoundParameters.ContainsKey('displayName')) {
                    $json = $json + " displayName: `"$displayName`","
                }
                if ($PSBoundParameters.ContainsKey('groupTag')) {
                    $json = $json + " groupTag: `"$groupTag`""
                }
                else {
                    $json = $json.Trim(",")
                }
                $json = $json + " }"

                Write-Verbose "POST $uri`n$json"

                try {
                    Invoke-MgGraphRequest -Uri $uri -Method POST -Body $json -ContentType "application/json" -OutputType PSObject
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }
            }
        }

    
        Function Remove-AutopilotDevice() {
            <#
.SYNOPSIS
Removes a specific device currently registered with Windows Autopilot.
  
.DESCRIPTION
The Remove-AutopilotDevice cmdlet removes the specified device, identified by its ID, from the list of devices registered with Windows Autopilot for the current Azure AD tenant.
  
.PARAMETER id
Specifies the ID (GUID) for a specific Windows Autopilot device
  
.EXAMPLE
Remove all Windows Autopilot devices from the current Azure AD tenant
  
Get-AutopilotDevice | Remove-AutopilotDevice
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $True)] $id,
                [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)] $serialNumber
            )

            Begin {
                $bulkList = @()
            }

            Process {

                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/windowsAutopilotDeviceIdentities"    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"

                try {
                    Write-Verbose "DELETE $uri"
                    Invoke-MgGraphRequest -Uri $uri -Method DELETE
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }
        
            }
        }


        Function Get-AutopilotImportedDevice() {
            <#
.SYNOPSIS
Gets information about devices being imported into Windows Autopilot.
  
.DESCRIPTION
The Get-AutopilotImportedDevice cmdlet retrieves either the full list of devices being imported into Windows Autopilot for the current Azure AD tenant, or information for a specific device if the ID of the device is specified. Once the import is complete, the information instance is expected to be deleted.
  
.PARAMETER id
Optionally specifies the ID (GUID) for a specific Windows Autopilot device being imported.
  
.EXAMPLE
Get a list of all devices being imported into Windows Autopilot for the current Azure AD tenant.
  
Get-AutopilotImportedDevice
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $false)] $id = $null,
                [Parameter(Mandatory = $false)] $serial
            )

            # Defining Variables
            $graphApiVersion = "beta"
            if ($id) {
                $uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/importedWindowsAutopilotDeviceIdentities/$id"
            } 
            elseif ($serial) {
                # handles also serial numbers with spaces
                $uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/importedWindowsAutopilotDeviceIdentities/?`$filter=contains(serialNumber,'$serial')"
            }
            else {
                $uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/importedWindowsAutopilotDeviceIdentities"
            }

            Write-Verbose "GET $uri"

            try {
                $response = Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject
                if ($id) {
                    $response
                }
                else {
                    $devices = $response.value
    
                    $devicesNextLink = $response."@odata.nextLink"
    
                    while ($null -ne $devicesNextLink) {
                        $devicesResponse = (Invoke-MgGraphRequest -Uri $devicesNextLink -Method Get -OutputType PSObject)
                        $devicesNextLink = $devicesResponse."@odata.nextLink"
                        $devices += $devicesResponse.value
                    }
    
                    $devices
                }
            }
            catch {
                Write-Error $_.Exception 
                break
            }

        }


        <#
.SYNOPSIS
Adds a new device to Windows Autopilot.
  
.DESCRIPTION
The Add-AutopilotImportedDevice cmdlet adds the specified device to Windows Autopilot for the current Azure AD tenant. Note that a status object is returned when this cmdlet completes; the actual import process is performed as a background batch process by the Microsoft Intune service.
  
.PARAMETER serialNumber
The hardware serial number of the device being added (mandatory).
  
.PARAMETER hardwareIdentifier
The hardware hash (4K string) that uniquely identifies the device.
  
.PARAMETER groupTag
An optional identifier or tag that can be associated with this device, useful for grouping devices using Azure AD dynamic groups.
  
.PARAMETER displayName
The optional name (computer name) to be assigned to the device when it is deployed via Windows Autopilot. This is presently only supported with Azure AD Join scenarios. Note that names should not exceed 15 characters. After setting the name, you need to initiate a sync (Invoke-AutopilotSync) in order to see the name in the Intune object.
  
.PARAMETER assignedUser
The optional user UPN to be assigned to the device. Note that no validation is done on the UPN specified.
  
.EXAMPLE
Add a new device to Windows Autopilot for the current Azure AD tenant.
  
Add-AutopilotImportedDevice -serialNumber $serial -hardwareIdentifier $hash -groupTag "Kiosk" -assignedUser "anna@contoso.com"
#>
        Function Add-AutopilotImportedDevice() {
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true)] $serialNumber,
                [Parameter(Mandatory = $true)] $hardwareIdentifier,
                [Parameter(Mandatory = $false)] [Alias("orderIdentifier")] $groupTag = "",
                [Parameter(ParameterSetName = "Prop2")][Alias("UPN")] $assignedUser = ""
            )

            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/importedWindowsAutopilotDeviceIdentities"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            $json = @"
{
    "@odata.type": "#microsoft.graph.importedWindowsAutopilotDeviceIdentity",
    "groupTag": "$groupTag",
    "serialNumber": "$serialNumber",
    "productKey": "",
    "hardwareIdentifier": "$hardwareIdentifier",
    "assignedUserPrincipalName": "$assignedUser",
    "state": {
        "@odata.type": "microsoft.graph.importedWindowsAutopilotDeviceIdentityState",
        "deviceImportStatus": "pending",
        "deviceRegistrationId": "",
        "deviceErrorCode": 0,
        "deviceErrorName": ""
    }
}
"@

            Write-Verbose "POST $uri`n$json"

            try {
                Invoke-MgGraphRequest -Uri $uri -Method Post -Body $json -ContentType "application/json"
            }
            catch {
                Write-Error $_.Exception 
                break
            }
    
        }

    
        Function Remove-AutopilotImportedDevice() {
            <#
.SYNOPSIS
Removes the status information for a device being imported into Windows Autopilot.
  
.DESCRIPTION
The Remove-AutopilotImportedDevice cmdlet cleans up the status information about a new device being imported into Windows Autopilot. This should be done regardless of whether the import was successful or not.
  
.PARAMETER id
The ID (GUID) of the imported device status information to be removed (mandatory).
  
.EXAMPLE
Remove the status information for a specified device.
  
Remove-AutopilotImportedDevice -id $id
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $True)] $id
            )

            Process {

                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/importedWindowsAutopilotDeviceIdentities"    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"

                try {
                    Write-Verbose "DELETE $uri"
                    Invoke-MgGraphRequest -Uri $uri -Method DELETE
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }

            }
        
        }


        Function Get-AutopilotProfile() {
            <#
.SYNOPSIS
Gets Windows Autopilot profile details.
  
.DESCRIPTION
The Get-AutopilotProfile cmdlet returns either a list of all Windows Autopilot profiles for the current Azure AD tenant, or information for the specific profile specified by its ID.
  
.PARAMETER id
Optionally, the ID (GUID) of the profile to be retrieved.
  
.EXAMPLE
Get a list of all Windows Autopilot profiles.
  
Get-AutopilotProfile
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $false)] $id
            )

            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"

            if ($id) {
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"
            }
            else {
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            }

            Write-Verbose "GET $uri"

            try {
                $response = Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject
                if ($id) {
                    $response
                }
                else {
                    $devices = $response.value
    
                    $devicesNextLink = $response."@odata.nextLink"
    
                    while ($null -ne $devicesNextLink) {
                        $devicesResponse = (Invoke-MgGraphRequest -Uri $devicesNextLink -Method Get -OutputType PSObject)
                        $devicesNextLink = $devicesResponse."@odata.nextLink"
                        $devices += $devicesResponse.value
                    }
    
                    $devices
                }
            }
            catch {
                Write-Error $_.Exception 
                break
            }

        }


        Function Get-AutopilotProfileAssignedDevice() {
            <#
.SYNOPSIS
Gets the list of devices that are assigned to the specified Windows Autopilot profile.
  
.DESCRIPTION
The Get-AutopilotProfileAssignedDevice cmdlet returns the list of Autopilot devices that have been assigned the specified Windows Autopilot profile.
  
.PARAMETER id
The ID (GUID) of the profile to be retrieved.
  
.EXAMPLE
Get a list of all Windows Autopilot profiles.
  
Get-AutopilotProfileAssignedDevices -id $id
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)] $id
            )

            Process {

                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id/assignedDevices"

                Write-Verbose "GET $uri"

                try {
                    $response = Invoke-MgGraphRequest -Uri $uri -Method Get
                    $response.Value
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }
            }
        }



        Function ConvertTo-AutopilotConfigurationJSON() {
            <#
.SYNOPSIS
Converts the specified Windows Autopilot profile into a JSON format.
  
.DESCRIPTION
The ConvertTo-AutopilotConfigurationJSON cmdlet converts the specified Windows Autopilot profile, as represented by a Microsoft Graph API object, into a JSON format.
  
.PARAMETER profile
A Windows Autopilot profile object, typically returned by Get-AutopilotProfile
  
.EXAMPLE
Get the JSON representation of each Windows Autopilot profile in the current Azure AD tenant.
  
Get-AutopilotProfile | ConvertTo-AutopilotConfigurationJSON
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
                [Object] $profile
            )

            Begin {

                # Set the org-related info
                $script:TenantOrg = Get-Organization
                foreach ($domain in $script:TenantOrg.VerifiedDomains) {
                    if ($domain.isDefault) {
                        $script:TenantDomain = $domain.name
                    }
                }
            }

            Process {

                $oobeSettings = $profile.outOfBoxExperienceSettings

                # Build up properties
                $json = @{}
                $json.Add("Comment_File", "Profile $($_.displayName)")
                $json.Add("Version", 2049)
                $json.Add("ZtdCorrelationId", $_.id)
                if ($profile."@odata.type" -eq "#microsoft.graph.activeDirectoryWindowsAutopilotDeploymentProfile") {
                    $json.Add("CloudAssignedDomainJoinMethod", 1)
                }
                else {
                    $json.Add("CloudAssignedDomainJoinMethod", 0)
                }
                if ($profile.deviceNameTemplate) {
                    $json.Add("CloudAssignedDeviceName", $_.deviceNameTemplate)
                }

                # Figure out config value
                $oobeConfig = 8 + 256
                if ($oobeSettings.userType -eq 'standard') {
                    $oobeConfig += 2
                }
                if ($oobeSettings.hidePrivacySettings -eq $true) {
                    $oobeConfig += 4
                }
                if ($oobeSettings.hideEULA -eq $true) {
                    $oobeConfig += 16
                }
                if ($oobeSettings.skipKeyboardSelectionPage -eq $true) {
                    $oobeConfig += 1024
                    if ($_.language) {
                        $json.Add("CloudAssignedLanguage", $_.language)
                        # Use the same value for region so that screen is skipped too
                        $json.Add("CloudAssignedRegion", $_.language)
                    }
                }
                if ($oobeSettings.deviceUsageType -eq 'shared') {
                    $oobeConfig += 32 + 64
                }
                $json.Add("CloudAssignedOobeConfig", $oobeConfig)

                # Set the forced enrollment setting
                if ($oobeSettings.hideEscapeLink -eq $true) {
                    $json.Add("CloudAssignedForcedEnrollment", 1)
                }
                else {
                    $json.Add("CloudAssignedForcedEnrollment", 0)
                }

                $json.Add("CloudAssignedTenantId", $script:TenantOrg.id)
                $json.Add("CloudAssignedTenantDomain", $script:TenantDomain)
                $embedded = @{}
                $embedded.Add("CloudAssignedTenantDomain", $script:TenantDomain)
                $embedded.Add("CloudAssignedTenantUpn", "")
                if ($oobeSettings.hideEscapeLink -eq $true) {
                    $embedded.Add("ForcedEnrollment", 1)
                }
                else {
                    $embedded.Add("ForcedEnrollment", 0)
                }
                $ztc = @{}
                $ztc.Add("ZeroTouchConfig", $embedded)
                $json.Add("CloudAssignedAadServerData", (ConvertTo-Json $ztc -Compress))

                # Skip connectivity check
                if ($profile.hybridAzureADJoinSkipConnectivityCheck -eq $true) {
                    $json.Add("HybridJoinSkipDCConnectivityCheck", 1)
                }

                # Hard-code properties not represented in Intune
                $json.Add("CloudAssignedAutopilotUpdateDisabled", 1)
                $json.Add("CloudAssignedAutopilotUpdateTimeout", 1800000)

                # Return the JSON
                ConvertTo-Json $json
            }

        }


        Function Set-AutopilotProfile() {
            <#
.SYNOPSIS
Sets Windows Autopilot profile properties on an existing Autopilot profile.
  
.DESCRIPTION
The Set-AutopilotProfile cmdlet sets properties on an existing Autopilot profile.
  
.PARAMETER id
The GUID of the profile to be updated.
  
.PARAMETER displayName
The name of the Windows Autopilot profile to create. (This value cannot contain spaces.)
  
.PARAMETER description
The description to be configured in the profile. (This value cannot contain dashes.)
  
.PARAMETER ConvertDeviceToAutopilot
Configure the value "Convert all targeted devices to Autopilot"
  
.PARAMETER AllEnabled
Enable everything that can be enabled
  
.PARAMETER AllDisabled
Disable everything that can be disabled
  
.PARAMETER OOBE_HideEULA
Configure the OOBE option to hide or not the EULA
  
.PARAMETER OOBE_EnableWhiteGlove
Configure the OOBE option to allow or not White Glove OOBE
  
.PARAMETER OOBE_HidePrivacySettings
Configure the OOBE option to hide or not the privacy settings
  
.PARAMETER OOBE_HideChangeAccountOpts
Configure the OOBE option to hide or not the change account options
  
.PARAMETER OOBE_UserTypeAdmin
Configure the user account type as administrator.
  
.PARAMETER OOBE_NameTemplate
Configure the OOBE option to apply a device name template
  
.PARAMETER OOBE_language
The language identifier (e.g. "en-us") to be configured in the profile
  
.PARAMETER OOBE_SkipKeyboard
Configure the OOBE option to skip or not the keyboard selection page
  
.PARAMETER OOBE_HideChangeAccountOpts
Configure the OOBE option to hide or not the change account options
  
.PARAMETER OOBE_SkipConnectivityCheck
Specify whether to skip Active Directory connectivity check (UserDrivenAAD only)
  
.EXAMPLE
Update an existing Autopilot profile to specify a language:
  
Set-AutopilotProfile -ID <guid> -Language "en-us"
  
.EXAMPLE
Update an existing Autopilot profile to set multiple properties:
  
Set-AutopilotProfile -ID <guid> -Language "en-us" -displayname "My testing profile" -Description "Description of my profile" -OOBE_HideEULA $True -OOBE_hidePrivacySettings $True
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $True)] $id,
                [Parameter(ParameterSetName = 'notAll')][string] $displayName,
                [Parameter(ParameterSetName = 'notAll')][string] $description,
                [Parameter(ParameterSetName = 'notAll')][Switch] $ConvertDeviceToAutopilot,
                [Parameter(ParameterSetName = 'notAll')][string] $OOBE_language,
                [Parameter(ParameterSetName = 'notAll')][Switch] $OOBE_skipKeyboard,
                [Parameter(ParameterSetName = 'notAll')][string] $OOBE_NameTemplate,
                [Parameter(ParameterSetName = 'notAll')][Switch] $OOBE_EnableWhiteGlove,
                [Parameter(ParameterSetName = 'notAll')][Switch] $OOBE_UserTypeAdmin,
                [Parameter(ParameterSetName = 'AllEnabled', Mandatory = $true)][Switch] $AllEnabled, 
                [Parameter(ParameterSetName = 'AllDisabled', Mandatory = $true)][Switch] $AllDisabled, 
                [Parameter(ParameterSetName = 'notAll')][Switch] $OOBE_HideEULA,
                [Parameter(ParameterSetName = 'notAll')][Switch] $OOBE_hidePrivacySettings,
                [Parameter(ParameterSetName = 'notAll')][Switch] $OOBE_HideChangeAccountOpts,
                [Parameter(ParameterSetName = 'notAll')][Switch] $OOBE_SkipConnectivityCheck
            )

            # Get the current values
            $current = Get-AutopilotProfile -id $id

            # If this is a Hybrid AADJ profile, make sure it has the needed property
            if ($current.'@odata.type' -eq "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile") {
                if (-not ($current.PSObject.Properties | Where-Object { $_.Name -eq "hybridAzureADJoinSkipConnectivityCheck" })) {
                    $current | Add-Member -NotePropertyName hybridAzureADJoinSkipConnectivityCheck -NotePropertyValue $false
                }
            }

            # For parameters that were specified, update that object in place
            if ($PSBoundParameters.ContainsKey('displayName')) { $current.displayName = $displayName }
            if ($PSBoundParameters.ContainsKey('description')) { $current.description = $description }
            if ($PSBoundParameters.ContainsKey('ConvertDeviceToAutopilot')) { $current.extractHardwareHash = [bool]$ConvertDeviceToAutopilot }
            if ($PSBoundParameters.ContainsKey('OOBE_language')) { $current.language = $OOBE_language }
            if ($PSBoundParameters.ContainsKey('OOBE_skipKeyboard')) { $current.outOfBoxExperienceSettings.skipKeyboardSelectionPage = [bool]$OOBE_skipKeyboard }
            if ($PSBoundParameters.ContainsKey('OOBE_NameTemplate')) { $current.deviceNameTemplate = $OOBE_NameTemplate }
            if ($PSBoundParameters.ContainsKey('OOBE_EnableWhiteGlove')) { $current.enableWhiteGlove = [bool]$OOBE_EnableWhiteGlove }
            if ($PSBoundParameters.ContainsKey('OOBE_UserTypeAdmin')) {
                if ($OOBE_UserTypeAdmin) {
                    $current.outOfBoxExperienceSettings.userType = "administrator"
                }
                else {
                    $current.outOfBoxExperienceSettings.userType = "standard"
                }
            }
            if ($PSBoundParameters.ContainsKey('OOBE_HideEULA')) { $current.outOfBoxExperienceSettings.hideEULA = [bool]$OOBE_HideEULA }
            if ($PSBoundParameters.ContainsKey('OOBE_HidePrivacySettings')) { $current.outOfBoxExperienceSettings.hidePrivacySettings = [bool]$OOBE_HidePrivacySettings }
            if ($PSBoundParameters.ContainsKey('OOBE_HideChangeAccountOpts')) { $current.outOfBoxExperienceSettings.hideEscapeLink = [bool]$OOBE_HideChangeAccountOpts }
            if ($PSBoundParameters.ContainsKey('OOBE_SkipConnectivityCheck')) { $current.hybridAzureADJoinSkipConnectivityCheck = [bool]$OOBE_SkipConnectivityCheck }

            if ($AllEnabled) {
                $current.extractHardwareHash = $true
                $current.outOfBoxExperienceSettings.hidePrivacySettings = $true
                $current.outOfBoxExperienceSettings.hideEscapeLink = $true
                $current.hybridAzureADJoinSkipConnectivityCheck = $true
                $current.EnableWhiteGlove = $true
                $current.outOfBoxExperienceSettings.hideEULA = $true 
                $current.outOfBoxExperienceSettings.hidePrivacySettings = $true
                $current.outOfBoxExperienceSettings.hideEscapeLink = $true
                $current.outOfBoxExperienceSettings.skipKeyboardSelectionPage = $true
                $current.outOfBoxExperienceSettings.userType = "administrator"
            }
            elseif ($AllDisabled) {
                $current.extractHardwareHash = $false
                $current.outOfBoxExperienceSettings.hidePrivacySettings = $false
                $current.outOfBoxExperienceSettings.hideEscapeLink = $false
                $current.hybridAzureADJoinSkipConnectivityCheck = $false
                $current.EnableWhiteGlove = $false
                $current.outOfBoxExperienceSettings.hideEULA = $false
                $current.outOfBoxExperienceSettings.hidePrivacySettings = $false
                $current.outOfBoxExperienceSettings.hideEscapeLink = $false
                $current.outOfBoxExperienceSettings.skipKeyboardSelectionPage = $false
                $current.outOfBoxExperienceSettings.userType = "standard"
            }

            # Clean up unneeded properties
            $current.PSObject.Properties.Remove("lastModifiedDateTime")
            $current.PSObject.Properties.Remove("createdDateTime") 
            $current.PSObject.Properties.Remove("@odata.context")
            $current.PSObject.Properties.Remove("id")
            $current.PSObject.Properties.Remove("roleScopeTagIds")

            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"
            $json = ($current | ConvertTo-Json).ToString()
    
            Write-Verbose "PATCH $uri`n$json"

            try {
                Invoke-MgGraphRequest -Uri $uri -Method PATCH -Body $json -ContentType "application/json" -OutputType PSObject
            }
            catch {
                Write-Error $_.Exception 
                break
            }

        }


        Function New-AutopilotProfile() {
            <#
.SYNOPSIS
Creates a new Autopilot profile.
  
.DESCRIPTION
The New-AutopilotProfile creates a new Autopilot profile.
  
.PARAMETER displayName
The name of the Windows Autopilot profile to create. (This value cannot contain spaces.)
  
.PARAMETER mode
The type of Autopilot profile to create. Choices are "UserDrivenAAD", "UserDrivenAD", and "SelfDeployingAAD".
  
.PARAMETER description
The description to be configured in the profile. (This value cannot contain dashes.)
      
.PARAMETER ConvertDeviceToAutopilot
Configure the value "Convert all targeted devices to Autopilot"
  
.PARAMETER OOBE_HideEULA
Configure the OOBE option to hide or not the EULA
  
.PARAMETER OOBE_EnableWhiteGlove
Configure the OOBE option to allow or not White Glove OOBE
  
.PARAMETER OOBE_HidePrivacySettings
Configure the OOBE option to hide or not the privacy settings
  
.PARAMETER OOBE_HideChangeAccountOpts
Configure the OOBE option to hide or not the change account options
  
.PARAMETER OOBE_UserTypeAdmin
Configure the user account type as administrator.
  
.PARAMETER OOBE_NameTemplate
Configure the OOBE option to apply a device name template
  
.PARAMETER OOBE_language
The language identifier (e.g. "en-us") to be configured in the profile
  
.PARAMETER OOBE_SkipKeyboard
Configure the OOBE option to skip or not the keyboard selection page
  
.PARAMETER OOBE_HideChangeAccountOpts
Configure the OOBE option to hide or not the change account options
  
.PARAMETER OOBE_SkipConnectivityCheck
Specify whether to skip Active Directory connectivity checks (UserDrivenAAD only)
  
.EXAMPLE
Create profiles of different types:
  
New-AutopilotProfile -mode UserDrivenAAD -displayName "My AAD profile" -description "My user-driven AAD profile" -OOBE_Quiet
New-AutopilotProfile -mode UserDrivenAD -displayName "My AD profile" -description "My user-driven AD profile" -OOBE_Quiet
New-AutopilotProfile -mode SelfDeployingAAD -displayName "My Self Deploying profile" -description "My self-deploying profile" -OOBE_Quiet
  
.EXAMPLE
Create a user-driven AAD profile:
  
New-AutopilotProfile -mode UserDrivenAAD -displayName "My testing profile" -Description "Description of my profile" -OOBE_Language "en-us" -OOBE_HideEULA -OOBE_HidePrivacySettings
  
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true)][string] $displayName,
                [Parameter(Mandatory = $true)][ValidateSet('UserDrivenAAD', 'UserDrivenAD', 'SelfDeployingAAD')][string] $mode, 
                [string] $description,
                [Switch] $ConvertDeviceToAutopilot,
                [string] $OOBE_language,
                [Switch] $OOBE_skipKeyboard,
                [string] $OOBE_NameTemplate,
                [Switch] $OOBE_EnableWhiteGlove,
                [Switch] $OOBE_UserTypeAdmin,
                [Switch] $OOBE_HideEULA,
                [Switch] $OOBE_hidePrivacySettings,
                [Switch] $OOBE_HideChangeAccountOpts,
                [Switch] $OOBE_SkipConnectivityCheck
            )

            # Adjust values as needed
            switch ($mode) {
                "UserDrivenAAD" { $odataType = "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile"; $usage = "singleUser" }
                "SelfDeployingAAD" { $odataType = "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile"; $usage = "shared" }
                "UserDrivenAD" { $odataType = "#microsoft.graph.activeDirectoryWindowsAutopilotDeploymentProfile"; $usage = "singleUser" }
            }

            if ($OOBE_UserTypeAdmin) {        
                $OOBE_userType = "administrator"
            }
            else {        
                $OOBE_userType = "standard"
            }        

            if ($OOBE_EnableWhiteGlove) {        
                $OOBE_HideChangeAccountOpts = $True
            }        
        
            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            if ($mode -eq "UserDrivenAD") {
                $json = @"
{
    "@odata.type": "$odataType",
    "displayName": "$displayname",
    "description": "$description",
    "language": "$OOBE_language",
    "extractHardwareHash": $(BoolToString($ConvertDeviceToAutopilot)),
    "deviceNameTemplate": "$OOBE_NameTemplate",
    "deviceType": "windowsPc",
    "enableWhiteGlove": $(BoolToString($OOBE_EnableWhiteGlove)),
    "hybridAzureADJoinSkipConnectivityCheck": $(BoolToString($OOBE_SkipConnectivityChecks)),
    "outOfBoxExperienceSettings": {
        "hidePrivacySettings": $(BoolToString($OOBE_hidePrivacySettings)),
        "hideEULA": $(BoolToString($OOBE_HideEULA)),
        "userType": "$OOBE_userType",
        "deviceUsageType": "$usage",
        "skipKeyboardSelectionPage": $(BoolToString($OOBE_skipKeyboard)),
        "hideEscapeLink": $(BoolToString($OOBE_HideChangeAccountOpts))
    }
}
"@
            }
            else {
                $json = @"
{
    "@odata.type": "$odataType",
    "displayName": "$displayname",
    "description": "$description",
    "language": "$OOBE_language",
    "extractHardwareHash": $(BoolToString($ConvertDeviceToAutopilot)),
    "deviceNameTemplate": "$OOBE_NameTemplate",
    "deviceType": "windowsPc",
    "enableWhiteGlove": $(BoolToString($OOBE_EnableWhiteGlove)),
    "outOfBoxExperienceSettings": {
        "hidePrivacySettings": $(BoolToString($OOBE_hidePrivacySettings)),
        "hideEULA": $(BoolToString($OOBE_HideEULA)),
        "userType": "$OOBE_userType",
        "deviceUsageType": "$usage",
        "skipKeyboardSelectionPage": $(BoolToString($OOBE_skipKeyboard)),
        "hideEscapeLink": $(BoolToString($OOBE_HideChangeAccountOpts))
    }
}
"@
            }

            Write-Verbose "POST $uri`n$json"

            try {
                Invoke-MgGraphRequest -Uri $uri -Method POST -Body $json -ContentType "application/json" -OutputType PSObject
            }
            catch {
                Write-Error $_.Exception 
                break
            }

        }


        Function Remove-AutopilotProfile() {
            <#
.SYNOPSIS
Remove a Deployment Profile
.DESCRIPTION
The Remove-AutopilotProfile allows you to remove a specific deployment profile
.PARAMETER id
Mandatory, the ID (GUID) of the profile to be removed.
.EXAMPLE
Remove-AutopilotProfile -id $id
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] $id
            )

            Process {
                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"

                Write-Verbose "DELETE $uri"

                Try {
                    Invoke-MgGraphRequest -Uri $uri -Method DELETE
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }
            }
        }


        Function Get-AutopilotProfileAssignments() {
            <#
.SYNOPSIS
List all assigned devices for a specific profile ID
.DESCRIPTION
The Get-AutopilotProfileAssignments cmdlet returns the list of groups that ae assigned to a spcific deployment profile
.PARAMETER id
Type: Integer - Mandatory, the ID (GUID) of the profile to be retrieved.
.EXAMPLE
Get-AutopilotProfileAssignments -id $id
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $True)] $id
            )

            Process {

                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id/assignments"

                Write-Verbose "GET $uri"

                try {
                    $response = Invoke-MgGraphRequest -Uri $uri -Method Get
                    $Group_ID = $response.Value.target.groupId
                    ForEach ($Group in $Group_ID) {
                        Try {
                            Get-MgGroup | Where-Object { $_.ObjectId -like $Group }
                        }
                        Catch {
                            $Group
                        }            
                    }
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }

            }

        }


        Function Remove-AutopilotProfileAssignments() {
            <#
.SYNOPSIS
Removes a specific group assigntion for a specifc deployment profile
.DESCRIPTION
The Remove-AutopilotProfileAssignments cmdlet allows you to remove a group assignation for a deployment profile
.PARAMETER id
Type: Integer - Mandatory, the ID (GUID) of the profile
.PARAMETER groupid
Type: Integer - Mandatory, the ID of the group
.EXAMPLE
Remove-AutopilotProfileAssignments -id $id
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true)]$id,
                [Parameter(Mandatory = $true)]$groupid
            )
            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
    
            $full_assignment_id = $id + "_" + $groupid + "_0"

            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id/assignments/$full_assignment_id"

            Write-Verbose "DELETE $uri"

            try {
                Invoke-MgGraphRequest -Uri $uri -Method DELETE
            }
            catch {
                Write-Error $_.Exception 
                break
            }

        }


        Function Set-AutopilotProfileAssignedGroup() {
            <#
.SYNOPSIS
Assigns a group to a Windows Autopilot profile.
.DESCRIPTION
The Set-AutopilotProfileAssignedGroup cmdlet allows you to assign a specific group to a specific deployment profile
.PARAMETER id
Type: Integer - Mandatory, the ID (GUID) of the profile
.PARAMETER groupid
Type: Integer - Mandatory, the ID of the group
.EXAMPLE
Set-AutopilotProfileAssignedGroup -id $id -groupid $groupid
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true)]$id,
                [Parameter(Mandatory = $true)]$groupid
            )
            $full_assignment_id = $id + "_" + $groupid + "_0"  
  
            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"        
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id/assignments"        

            $json = @"
{
    "id": "$full_assignment_id",
    "target": {
        "@odata.type": "#microsoft.graph.groupAssignmentTarget",
        "groupId": "$groupid"
    }
}
"@

            Write-Verbose "POST $uri`n$json"

            try {
                Invoke-MgGraphRequest -Uri $uri -Method Post -Body $json -ContentType "application/json" -OutputType PSObject
            }
            catch {
                Write-Error $_.Exception 
                break
            }
        }


        Function Get-EnrollmentStatusPage() {
            <#
.SYNOPSIS
List enrollment status page
.DESCRIPTION
The Get-EnrollmentStatusPage cmdlet returns available enrollment status page with their options
.PARAMETER id
The ID (GUID) of the status page (optional)
.EXAMPLE
Get-EnrollmentStatusPage
#>

            [cmdletbinding()]
            param
            (
                [Parameter()] $id
            )

            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/deviceEnrollmentConfigurations"

            if ($id) {
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"
            }
            else {
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            }

            Write-Verbose "GET $uri"

            try {
                $response = Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject
                if ($id) {
                    $response
                }
                else {
                    $response.Value | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration" }
                }
            }
            catch {
                Write-Error $_.Exception 
                break
            }

        }


        Function Add-EnrollmentStatusPage() {
            <#
.SYNOPSIS
Adds a new Windows Autopilot Enrollment Status Page.
.DESCRIPTION
The Add-EnrollmentStatusPage cmdlet sets properties on an existing Autopilot profile.
.PARAMETER DisplayName
Type: String - Configure the display name of the enrollment status page
.PARAMETER description
Type: String - Configure the description of the enrollment status page
.PARAMETER HideProgress
Type: Boolean - Configure the option: Show app and profile installation progress
.PARAMETER AllowCollectLogs
Type: Boolean - Configure the option: Allow users to collect logs about installation errors
.PARAMETER Message
Type: String - Configure the option: Show custom message when an error occurs
.PARAMETER AllowUseOnFailure
Type: Boolean - Configure the option: Allow users to use device if installation error occurs
.PARAMETER AllowResetOnError
Type: Boolean - Configure the option: Allow users to reset device if installation error occurs
.PARAMETER BlockDeviceUntilComplete
Type: Boolean - Configure the option: Block device use until all apps and profiles are installed
.PARAMETER TimeoutInMinutes
Type: Integer - Configure the option: Show error when installation takes longer than specified number of minutes
.EXAMPLE
Add-EnrollmentStatusPage -Message "Oops an error occured, please contact your support" -HideProgress $True -AllowResetOnError $True
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $True)][string]$DisplayName,
                [string]$Description,        
                [bool]$HideProgress,    
                [bool]$AllowCollectLogs,
                [bool]$blockDeviceSetupRetryByUser,    
                [string]$Message,    
                [bool]$AllowUseOnFailure,
                [bool]$AllowResetOnError,    
                [bool]$BlockDeviceUntilComplete,                
                [Int]$TimeoutInMinutes        
            )

            If ($HideProgress -eq $False) {
                $blockDeviceSetupRetryByUser = $true
            }

            If (($Description -eq $null)) {
                $Description = $EnrollmentPage_Description
            }        

            If (($DisplayName -eq $null)) {
                $DisplayName = ""
            }    

            If (($TimeoutInMinutes -eq "")) {
                $TimeoutInMinutes = "60"
            }                

            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/deviceEnrollmentConfigurations"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            $json = @"
{
    "@odata.type": "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration",
    "displayName": "$DisplayName",
    "description": "$description",
    "showInstallationProgress": "$hideprogress",
    "blockDeviceSetupRetryByUser": "$blockDeviceSetupRetryByUser",
    "allowDeviceResetOnInstallFailure": "$AllowResetOnError",
    "allowLogCollectionOnInstallFailure": "$AllowCollectLogs",
    "customErrorMessage": "$Message",
    "installProgressTimeoutInMinutes": "$TimeoutInMinutes",
    "allowDeviceUseOnInstallFailure": "$AllowUseOnFailure",
}
"@

            Write-Verbose "POST $uri`n$json"

            try {
                Invoke-MgGraphRequest -Uri $uri -Method Post -Body $json -ContentType "application/json" -OutputType PSObject
            }
            catch {
                Write-Error $_.Exception 
                break
            }

        }


        Function Set-EnrollmentStatusPage() {
            <#
.SYNOPSIS
Sets Windows Autopilot Enrollment Status Page properties.
.DESCRIPTION
The Set-EnrollmentStatusPage cmdlet sets properties on an existing Autopilot profile.
.PARAMETER id
The ID (GUID) of the profile to be updated.
.PARAMETER DisplayName
Type: String - Configure the display name of the enrollment status page
.PARAMETER description
Type: String - Configure the description of the enrollment status page
.PARAMETER HideProgress
Type: Boolean - Configure the option: Show app and profile installation progress
.PARAMETER AllowCollectLogs
Type: Boolean - Configure the option: Allow users to collect logs about installation errors
.PARAMETER Message
Type: String - Configure the option: Show custom message when an error occurs
.PARAMETER AllowUseOnFailure
Type: Boolean - Configure the option: Allow users to use device if installation error occurs
.PARAMETER AllowResetOnError
Type: Boolean - Configure the option: Allow users to reset device if installation error occurs
.PARAMETER BlockDeviceUntilComplete
Type: Boolean - Configure the option: Block device use until all apps and profiles are installed
.PARAMETER TimeoutInMinutes
Type: Integer - Configure the option: Show error when installation takes longer than specified number of minutes
.EXAMPLE
Set-EnrollmentStatusPage -id $id -Message "Oops an error occured, please contact your support" -HideProgress $True -AllowResetOnError $True
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $True)] $id,
                [string]$DisplayName,    
                [string]$Description,        
                [bool]$HideProgress,
                [bool]$AllowCollectLogs,
                [string]$Message,    
                [bool]$AllowUseOnFailure,
                [bool]$AllowResetOnError,    
                [bool]$AllowUseOnError,    
                [bool]$BlockDeviceUntilComplete,                
                [Int]$TimeoutInMinutes        
            )

            Process {

                # LIST EXISTING VALUES FOR THE SELECTING STAUS PAGE
                # Default profile values
                $EnrollmentPage_Values = Get-EnrollmentStatusPage -id $id
                $EnrollmentPage_DisplayName = $EnrollmentPage_Values.displayName
                $EnrollmentPage_Description = $EnrollmentPage_Values.description
                $EnrollmentPage_showInstallationProgress = $EnrollmentPage_Values.showInstallationProgress
                $EnrollmentPage_blockDeviceSetupRetryByUser = $EnrollmentPage_Values.blockDeviceSetupRetryByUser
                $EnrollmentPage_allowDeviceResetOnInstallFailure = $EnrollmentPage_Values.allowDeviceResetOnInstallFailure
                $EnrollmentPage_allowLogCollectionOnInstallFailure = $EnrollmentPage_Values.allowLogCollectionOnInstallFailure
                $EnrollmentPage_customErrorMessage = $EnrollmentPage_Values.customErrorMessage
                $EnrollmentPage_installProgressTimeoutInMinutes = $EnrollmentPage_Values.installProgressTimeoutInMinutes
                $EnrollmentPage_allowDeviceUseOnInstallFailure = $EnrollmentPage_Values.allowDeviceUseOnInstallFailure

                If (!($HideProgress)) {
                    $HideProgress = $EnrollmentPage_showInstallationProgress
                }    
    
                If (!($BlockDeviceUntilComplete)) {
                    $BlockDeviceUntilComplete = $EnrollmentPage_blockDeviceSetupRetryByUser
                }        
        
                If (!($AllowCollectLogs)) {
                    $AllowCollectLogs = $EnrollmentPage_allowLogCollectionOnInstallFailure
                }            
    
                If (!($AllowUseOnFailure)) {
                    $AllowUseOnFailure = $EnrollmentPage_allowDeviceUseOnInstallFailure
                }    

                If (($Message -eq "")) {
                    $Message = $EnrollmentPage_customErrorMessage
                }        
        
                If (($Description -eq $null)) {
                    $Description = $EnrollmentPage_Description
                }        

                If (($DisplayName -eq $null)) {
                    $DisplayName = $EnrollmentPage_DisplayName
                }    

                If (!($AllowResetOnError)) {
                    $AllowResetOnError = $EnrollmentPage_allowDeviceResetOnInstallFailure
                }    

                If (($TimeoutInMinutes -eq "")) {
                    $TimeoutInMinutes = $EnrollmentPage_installProgressTimeoutInMinutes
                }                

                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/deviceEnrollmentConfigurations"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"
                $json = @"
{
    "@odata.type": "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration",
    "displayName": "$DisplayName",
    "description": "$description",
    "showInstallationProgress": "$HideProgress",
    "blockDeviceSetupRetryByUser": "$BlockDeviceUntilComplete",
    "allowDeviceResetOnInstallFailure": "$AllowResetOnError",
    "allowLogCollectionOnInstallFailure": "$AllowCollectLogs",
    "customErrorMessage": "$Message",
    "installProgressTimeoutInMinutes": "$TimeoutInMinutes",
    "allowDeviceUseOnInstallFailure": "$AllowUseOnFailure"
}
"@

                Write-Verbose "PATCH $uri`n$json"

                try {
                    Invoke-MgGraphRequest -Uri $uri -Method PATCH -Body $json -ContentType "application/json" -OutputType PSObject
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }

            }

        }


        Function Remove-EnrollmentStatusPage() {
            <#
.SYNOPSIS
Remove a specific enrollment status page
.DESCRIPTION
The Remove-EnrollmentStatusPage allows you to remove a specific enrollment status page
.PARAMETER id
Mandatory, the ID (GUID) of the profile to be retrieved.
.EXAMPLE
Remove-EnrollmentStatusPage -id $id
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] $id
            )

            Process {

                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/deviceEnrollmentConfigurations"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"

                Write-Verbose "DELETE $uri"

                try {
                    Invoke-MgGraphRequest -Uri $uri -Method DELETE
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }

            }

        }


        Function Invoke-AutopilotSync() {
            <#
.SYNOPSIS
Initiates a synchronization of Windows Autopilot devices between the Autopilot deployment service and Intune.
  
.DESCRIPTION
The Invoke-AutopilotSync cmdlet initiates a synchronization between the Autopilot deployment service and Intune.
This can be done after importing new devices, to ensure that they appear in Intune in the list of registered
Autopilot devices. See https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/api/intune_enrollment_windowsautopilotsettings_sync
for more information.
  
.EXAMPLE
Initiate a synchronization.
  
Invoke-AutopilotSync
#>
            [cmdletbinding()]
            param
            (
            )
            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/windowsAutopilotSettings/sync"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

            Write-Verbose "POST $uri"

            try {
                Invoke-MgGraphRequest -Uri $uri -Method Post
            }
            catch {
                Write-Error $_.Exception 
                break
            }

        }

        Function Get-AutopilotSyncInfo() {
            <#
    .SYNOPSIS
    Returns details about the last Autopilot sync.
      
    .DESCRIPTION
    The Get-AutopilotSyncInfo cmdlet retrieves details about the sync status between Intune and the Autopilot service.
    See https://docs.microsoft.com/en-us/graph/api/resources/intune-enrollment-windowsautopilotsettings?view=graph-rest-beta
    for more information.
      
    .EXAMPLE
    Get-AutopilotSyncInfo
    #>
            [cmdletbinding()]
            param
            (
            )
            # Defining Variables
            $graphApiVersion = "beta"
            $Resource = "deviceManagement/windowsAutopilotSettings"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
    
            Write-Verbose "GET $uri"
    
            try {
                Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject
            }
            catch {
                Write-Error $_.Exception 
                break
            }
    
        }
    
        #endregion


        Function Import-AutopilotCSV() {
            <#
.SYNOPSIS
Adds a batch of new devices into Windows Autopilot.
  
.DESCRIPTION
The Import-AutopilotCSV cmdlet processes a list of new devices (contained in a CSV file) using a several of the other cmdlets included in this module. It is a convenient wrapper to handle the details. After the devices have been added, the cmdlet will continue to check the status of the import process. Once all devices have been processed (successfully or not) the cmdlet will complete. This can take several minutes, as the devices are processed by Intune as a background batch process.
  
.PARAMETER csvFile
The file containing the list of devices to be added.
  
.PARAMETER groupTag
An optional identifier or tag that can be associated with this device, useful for grouping devices using Azure AD dynamic groups. This value overrides an Group Tag value specified in the CSV file.
  
.EXAMPLE
Add a batch of devices to Windows Autopilot for the current Azure AD tenant.
  
Import-AutopilotCSV -csvFile C:\Devices.csv
#>
            [cmdletbinding()]
            param
            (
                [Parameter(Mandatory = $true)] $csvFile,
                [Parameter(Mandatory = $false)] [Alias("orderIdentifier")] $groupTag = ""
            )
    
            # Read CSV and process each device
            $devices = Import-Csv $csvFile
            $importedDevices = @()
            foreach ($device in $devices) {
                if ($groupTag -ne "") {
                    $o = $groupTag
                }
                elseif ($device.'Group Tag' -ne "") {
                    $o = $device.'Group Tag'
                }
                else {
                    $o = $device.'OrderID'
                }
                Add-AutopilotImportedDevice -serialNumber $device.'Device Serial Number' -hardwareIdentifier $device.'Hardware Hash' -groupTag $o -assignedUser $device.'Assigned User'
            }

            # While we could keep a list of all the IDs that we added and then check each one, it is
            # easier to just loop through all of them
            $processingCount = 1
            while ($processingCount -gt 0) {
                $deviceStatuses = @(Get-AutopilotImportedDevice)
                $deviceCount = $deviceStatuses.Length

                # Check to see if any devices are still processing
                $processingCount = 0
                foreach ($device in $deviceStatuses) {
                    if ($device.state.deviceImportStatus -eq "unknown") {
                        $processingCount = $processingCount + 1
                    }
                }
                Write-Host "Waiting for $processingCount of $deviceCount"

                # Still processing? Sleep before trying again.
                if ($processingCount -gt 0) {
                    Start-Sleep 15
                }
            }

            # Display the statuses
            $deviceStatuses | ForEach-Object {
                Write-Host "Serial number $($_.serialNumber): $($_.state.deviceImportStatus) $($_.state.deviceErrorCode) $($_.state.deviceErrorName)"
            }

            # Cleanup the imported device records
            $deviceStatuses | ForEach-Object {
                Remove-AutopilotImportedDevice -id $_.id
            }
        }


        Function Get-AutopilotEvent() {
            <#
.SYNOPSIS
Gets Windows Autopilot deployment events.
  
.DESCRIPTION
The Get-AutopilotEvent cmdlet retrieves the list of deployment events (the data that you would see in the "Autopilot deployments" report in the Intune portal).
  
.EXAMPLE
Get a list of all Windows Autopilot events
  
Get-AutopilotEvent
#>
            [cmdletbinding()]
            param
            (
            )

            Process {

                # Defining Variables
                $graphApiVersion = "beta"
                $Resource = "deviceManagement/autopilotEvents"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

                try {
                    $response = Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject
                    $devices = $response.value
                    $devicesNextLink = $response."@odata.nextLink"
    
                    while ($null -ne $devicesNextLink) {
                        $devicesResponse = (Invoke-MgGraphRequest -Uri $devicesNextLink -Method Get -OutputType PSObject)
                        $devicesNextLink = $devicesResponse."@odata.nextLink"
                        $devices += $devicesResponse.value
                    }
    
                    $devices
                }
                catch {
                    Write-Error $_.Exception 
                    break
                }
            }
        }

        function getdevicesandusers() {
            $alldevices = getallpagination -url "https://graph.microsoft.com/beta/devicemanagement/manageddevices"
            $outputarray = @()
            foreach ($value in $alldevices) {
                $objectdetails = [pscustomobject]@{
                    DeviceID        = $value.id
                    DeviceName      = $value.deviceName
                    OSVersion       = $value.operatingSystem
                    PrimaryUser     = $value.userPrincipalName
                    operatingSystem = $value.operatingSystem
                    AADID           = $value.azureActiveDirectoryDeviceId
                    SerialNumber    = $value.serialnumber

                }
    
    
                $outputarray += $objectdetails
    
            }
    
            return $outputarray
        }

        function getallpagination () {
            <#
    .SYNOPSIS
    This function is used to grab all items from Graph API that are paginated
    .DESCRIPTION
    The function connects to the Graph API Interface and gets all items from the API that are paginated
    .EXAMPLE
    getallpagination -url "https://graph.microsoft.com/v1.0/groups"
     Returns all items
    .NOTES
     NAME: getallpagination
    #>
            [cmdletbinding()]
        
            param
            (
                $url
            )
            $response = (Invoke-MgGraphRequest -Uri $url -Method Get -OutputType PSObject)
            $alloutput = $response.value
        
            $alloutputNextLink = $response."@odata.nextLink"
        
            while ($null -ne $alloutputNextLink) {
                $alloutputResponse = (Invoke-MgGraphRequest -Uri $alloutputNextLink -Method Get -OutputType PSObject)
                $alloutputNextLink = $alloutputResponse."@odata.nextLink"
                $alloutput += $alloutputResponse.value
            }
        
            return $alloutput
        }

        
        function check-importeddevice {
            <#
    .SYNOPSIS
    This function is used to check if a device identifier (Windows) already exists in the Intune environment
    .DESCRIPTION
    This function is used to check if a device identifier (Windows) already exists in the Intune environment
    .EXAMPLE
    check-importeddevice -manufacturer "Microsoft Corporation" -model "Virtual Machine" -serial "xxxxx"
    Returns true or false
    .NOTES
    NAME: check-importeddevice
    #>
    [cmdletbinding()]
    
    param
    (
        $manufacturer,
        $model,
        $serial
    )
    ##Check it exists
    $uri = "https://graph.microsoft.com/beta/deviceManagement/importedDeviceIdentities/searchExistingIdentities"
    $json = @"
    {
        "importedDeviceIdentities": [
            {
                "importedDeviceIdentifier": "$manufacturer,$model,$serial",
                "importedDeviceIdentityType": "manufacturerModelSerial"
            }
        ]
    }
"@
    $response = (Invoke-MgGraphRequest -Uri $uri -Method Post -Body $json -OutputType PSObject).value
    
    
    if (!$response) {
        return $false
    } else {
        return $true
    }
    
    }
    

function import-deviceidentifier {
<#
.SYNOPSIS
This function is used to import a device identifier (Windows) already exists in the Intune environment
.DESCRIPTION
This function is used to import a device identifier (Windows) already exists in the Intune environment
.EXAMPLE
import-deviceidentifier -manufacturer "Microsoft Corporation" -model "Virtual Machine" -serial "xxxxx"
Returns true or false
.NOTES
NAME: import-deviceidentifier
#>
[cmdletbinding()]

param
(
$manufacturer,
$model,
$serial
)
##Send it
$uri = "https://graph.microsoft.com/beta/deviceManagement/importedDeviceIdentities/importDeviceIdentityList"

$json = @"
{
"importedDeviceIdentities": [
    {
        "importedDeviceIdentifier": "$manufacturer,$model,$serial",
        "importedDeviceIdentityType": "manufacturerModelSerial"
    }
],
"overwriteImportedDeviceIdentities": false
}
"@
Invoke-MgGraphRequest -Uri $uri -Method Post -Body $json -OutputType PSObject
}



        # Connect
        if ($AppId -ne "") {
            Connect-ToGraph -AppId $AppId -AppSecret $AppSecret -Tenant $TenantId
        }
        else {
            $graph = Connect-ToGraph -scopes "Group.ReadWrite.All, Device.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, GroupMember.ReadWrite.All"
            Write-Host "Connected to Intune tenant $($graph.TenantId)"
            if ($AddToGroup) {
                $aadId = Connect-ToGraph -scopes "Group.ReadWrite.All, Device.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, GroupMember.ReadWrite.All"
                Write-Host "Connected to Azure AD tenant $($aadId.TenantId)"
            }
        }

        # Force the output to a file
        if ($OutputFile -eq "") {
            $OutputFile = "$($env:TEMP)\autopilot.csv"
        } 
    }
}



Process {

    ##Check ImportCSV is empty
    if ($InputFile -eq "") {

    foreach ($comp in $Name) {
        $bad = $false

        # Get a CIM session
        if ($comp -eq "localhost") {
            $session = New-CimSession
        }
        else {
            $session = New-CimSession -ComputerName $comp -Credential $Credential
        }

        # Get the common properties.
        Write-Verbose "Checking $comp"
        $serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber

        if ($identifier) {
            $cs = Get-CimInstance -CimSession $session -Class Win32_ComputerSystem
            $make = $cs.Manufacturer.Trim().Replace(".", "").Replace(",", "")
            $model = $cs.Model.Trim().Replace(".", "").Replace(",", "")
            
        }
        else {
        # Get the hash (if available)
        $devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
        if ($devDetail -and (-not $Force)) {
            $hash = $devDetail.DeviceHardwareData
        }
        else {
            $bad = $true
            $hash = ""
        }
    
        # If the hash isn't available, get the make and model
        if ($bad -or $Force) {
            $cs = Get-CimInstance -CimSession $session -Class Win32_ComputerSystem
            $make = $cs.Manufacturer.Trim()
            $model = $cs.Model.Trim()
            if ($Partner) {
                $bad = $false
            }
        }
        else {
            $make = ""
            $model = ""
        }
    }
        # Getting the PKID is generally problematic for anyone other than OEMs, so let's skip it here
        $product = ""

        # Depending on the format requested, create the necessary object
        if ($Partner) {
            # Create a pipeline object
            $c = New-Object psobject -Property @{
                "Device Serial Number" = $serial
                "Windows Product ID"   = $product
                "Hardware Hash"        = $hash
                "Manufacturer name"    = $make
                "Device model"         = $model
            }
            # From spec:
            # "Manufacturer Name" = $make
            # "Device Name" = $model

        }
        elseif ($identifier) {
            # Create a pipeline object
            $c = New-Object psobject -Property @{
                "Serial" = $serial
                "Manufacturer" = $make
                "Model" = $model
            }
        }
        else {
            # Create a pipeline object
            $c = New-Object psobject -Property @{
                "Device Serial Number" = $serial
                "Windows Product ID"   = $product
                "Hardware Hash"        = $hash
            }
            
            if ($GroupTag -ne "") {
                Add-Member -InputObject $c -NotePropertyName "Group Tag" -NotePropertyValue $GroupTag
            }
            if ($AssignedUser -ne "") {
                Add-Member -InputObject $c -NotePropertyName "Assigned User" -NotePropertyValue $AssignedUser
            }
        }

        # Write the object to the pipeline or array
        if ($bad) {
            # Report an error when the hash isn't available
            Write-Error -Message "Unable to retrieve device hardware data (hash) from computer $comp" -Category DeviceError
        }
        elseif ($OutputFile -eq "") {
            $c
        }
        else {
            $computers += $c
            Write-Host "Gathered details for device with serial number: $serial"
        }

        Remove-CimSession $session
    }
}
else {
    write-host "CSV Imported, skipping device check"
}

}

End {
    if ($OutputFile -ne "") {
        if ($Append) {
            if (Test-Path $OutputFile) {
                $computers += Import-Csv -Path $OutputFile
            }
        }
        if ($Partner) {
            $computers | Select-Object "Device Serial Number", "Windows Product ID", "Hardware Hash", "Manufacturer name", "Device model" | ConvertTo-Csv -NoTypeInformation | ForEach-Object { $_ -replace '"', '' } | Out-File $OutputFile
        }
        elseif ($AssignedUser -ne "") {
            $computers | Select-Object "Device Serial Number", "Windows Product ID", "Hardware Hash", "Group Tag", "Assigned User" | ConvertTo-Csv -NoTypeInformation | ForEach-Object { $_ -replace '"', '' } | Out-File $OutputFile
        }
        elseif ($GroupTag -ne "") {
            $computers | Select-Object "Device Serial Number", "Windows Product ID", "Hardware Hash", "Group Tag" | ConvertTo-Csv -NoTypeInformation | ForEach-Object { $_ -replace '"', '' } | Out-File $OutputFile
        }
        elseif ($identifier) {
            $computers | Select-Object "Manufacturer", "Model", "Serial" | ConvertTo-Csv -NoTypeInformation | ForEach-Object { $_ -replace '"', '' } | Select-Object -Skip 1 | Out-File $OutputFile
        }
        else {
            $computers | Select-Object "Device Serial Number", "Windows Product ID", "Hardware Hash" | ConvertTo-Csv -NoTypeInformation | ForEach-Object { $_ -replace '"', '' } | Out-File $OutputFile
        }
    }
    if ($Online) {

        if ($identifier) {
            if ($InputFile) {
                ##Import the CSV
                Import-Csv $InputFile -header "Manufacturer", "Model", "Serial" | ForEach-Object {
                    $serial = $_.Serial
                    $manufacturer = $_.Manufacturer
                    $model = $_.Model
                    write-host "Checking if device $serial exists in AutoPilot"
                    $exists = check-importeddevice -manufacturer $manufacturer -model $model -serial $serial
                    if ($exists -eq $false) {
                        write-host "Device $serial does not exist in AutoPilot, adding it"
                        $import = import-deviceidentifier -manufacturer $manufacturer -model $model -serial $serial
                        write-host "Device $serial added to AutoPilot"
                    }
                    else {
                        write-host "Device $serial already exists in AutoPilot"
                    }
                }
            }
            else {
                $computers | ForEach-Object {
                    $serial = $_.Serial
                    $manufacturer = $_.Manufacturer
                    $model = $_.Model
                    write-host "Checking if device $serial exists in AutoPilot"
                    $exists = check-importeddevice -manufacturer $manufacturer -model $model -serial $serial
                    if ($exists -eq $false) {
                        write-host "Device $serial does not exist in AutoPilot, adding it"
                        $import = import-deviceidentifier -manufacturer $manufacturer -model $model -serial $serial
                        write-host "Device $serial added to AutoPilot"
                    }
                    else {
                        write-host "Device $serial already exists in AutoPilot"
                    }
                }
            }

        }

        else {
        ##Check if $newdevice is false

        if ($newdevice) {
            $importStart = Get-Date
            $imported = @()
            $computers | ForEach-Object {
                # Add the devices
                "Adding New Device serial $($serial)"
                $importStart = Get-Date
                $imported = @()
                $computers | ForEach-Object {
                    $imported += Add-AutopilotImportedDevice -serialNumber $_.'Device Serial Number' -hardwareIdentifier $_.'Hardware Hash' -groupTag $_.'Group Tag' -assignedUser $_.'Assigned User'
                }
            }
        }
        else {
        
            Write-Host "Loading all objects. This can take a while on large tenants"
            # $aadDevices = getallpagination -url "https://graph.microsoft.com/beta/devices"

            $devices = getdevicesandusers

            $intunedevices = $devices | Where-Object { $_.operatingSystem -eq "Windows" }

            # Update existing devices by Thiago Beier https://twitter.com/thiagobeier https://www.linkedin.com/in/tbeier/
        
            $importStart = Get-Date
            $imported = @()
            $computers | ForEach-Object {
                $device = Get-AutopilotDevice | Where-Object { $_.serialNumber -eq "$($serial)" }
                if ($device) {
                    Write-Host "Device already exists in Autopilot"
                    $sanityCheckModel = $device.model
                    $sanityCheckLastSeen = $device.lastContactedDateTime.ToString("dddd dd/MM/yyyy hh:mm tt")
                    Write-Host "AutoPilot indicates model is a $sanityCheckModel, last checked-in $sanityCheckLastSeen."
                    ##Check if $delete has been set
                    if ($delete) {
                        Write-Host "Deleting device from AutoPilot"
                        Remove-AutopilotDevice -id $device.id
                        Write-Host "Device deleted from AutoPilot"

                    
                        $intunedevicetoremove = $intunedevices | Where-Object { $_.SerialNumber -eq "$($serial)" }       
                        $intunedeviceid = $intunedevicetoremove.DeviceID
                        $aaddeviceid = $intunedevicetoremove.AADID    
                        $aaduri = "https://graph.microsoft.com/beta/devices?`$filter=deviceID eq '$aaddeviceid'"
                        $aadobjectid = ((Invoke-MgGraphRequest -Uri $aaduri -Method GET -OutputType PSObject).value).id
                        Write-Host "Deleting device from Intune"
                        Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$intunedeviceid" -Method DELETE
                        Write-Host "Deleted device $serial from Intune"

                        Write-Host "Deleting Device from Entra ID"
                        Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/devices/$aadobjectid" -Method DELETE
                        Write-Host "Deleted device from Entra"

                        Write-Host "Adding back to Autopilot"
                        $imported += Add-AutopilotImportedDevice -serialNumber $_.'Device Serial Number' -hardwareIdentifier $_.'Hardware Hash' -groupTag $_.'Group Tag' -assignedUser $_.'Assigned User'

                    }
                    ##Elseif $grouptag is set
                    elseif ($updatetag) {
                        "Updating Existing Device - Working on device serial $($serial)"
                        $imported += Set-AutopilotDevice -id $device.Id -groupTag $GroupTag
    
                    }
                    else {
                        ##Prompt to delete or update
                        $choice = Read-Host "Do you want to delete or update? (delete/update)"

                        if ($choice -eq "delete") {
                            # Perform delete action
                            Write-Output "You chose to delete."
                            Write-Host "Deleting device from AutoPilot"
                            Remove-AutopilotDevice -id $device.id
                            Write-Host "Device deleted from AutoPilot"

    
                            $intunedevicetoremove = $intunedevices | Where-Object { $_.SerialNumber -eq "$($serial)" }       
                            $intunedeviceid = $intunedevicetoremove.DeviceID
                            $aaddeviceid = $intunedevicetoremove.AADID    
                            $aaduri = "https://graph.microsoft.com/beta/devices?`$filter=deviceID eq '$aaddeviceid'"
                            $aadobjectid = ((Invoke-MgGraphRequest -Uri $aaduri -Method GET -OutputType PSObject).value).id
                            Write-Host "Deleting device from Intune"
                            Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$intunedeviceid" -Method DELETE
                            Write-Host "Deleted device $serial from Intune"

                            Write-Host "Deleting Device from Entra ID"
                            Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/devices/$aadobjectid" -Method DELETE
                            Write-Host "Deleted device from Entra"

                            Write-Host "Adding back to Autopilot"
                            $imported += Add-AutopilotImportedDevice -serialNumber $_.'Device Serial Number' -hardwareIdentifier $_.'Hardware Hash' -groupTag $_.'Group Tag' -assignedUser $_.'Assigned User'

                        }
                        elseif ($choice -eq "update") {
                            # Perform update action
                            Write-Output "You chose to update."
                            "Updating Existing Device - Working on device serial $($serial)"
                            $imported += Set-AutopilotDevice -id $device.Id -groupTag $GroupTag

                        }
                        else {
                            Write-Output "Invalid choice. Please enter 'delete' or 'update'."
                            exit
                        }
                    }
                }
                else {
                    # Add the devices
                    "Adding New Device serial $($serial)"
                    $importStart = Get-Date
                    $imported = @()
                    $computers | ForEach-Object {
                        $imported += Add-AutopilotImportedDevice -serialNumber $_.'Device Serial Number' -hardwareIdentifier $_.'Hardware Hash' -groupTag $_.'Group Tag' -assignedUser $_.'Assigned User'
                    }
                }
            }
        
        }

        # Wait until the devices have been imported
        $processingCount = 1
        while ($processingCount -gt 0) {
            $current = @()
            $processingCount = 0
            $imported | ForEach-Object {
                #$device = Get-AutopilotImportedDevice -id $_.id
                $device = Get-AutopilotImportedDevice | Where-Object { $_.serialNumber -eq "$($serial)" }
                if ($device.state.deviceImportStatus -eq "unknown") {
                    $processingCount = $processingCount + 1
                }
                $current += $device
            }
            $deviceCount = $imported.Length
            Write-Host "Waiting for $processingCount of $deviceCount to be imported"
            if ($processingCount -gt 0) {
                Start-Sleep 30
            }
        }
        $importDuration = (Get-Date) - $importStart
        $importSeconds = [Math]::Ceiling($importDuration.TotalSeconds)
        $successCount = 0
        $current | ForEach-Object {
            Write-Host "$($device.serialNumber): $($device.state.deviceImportStatus) $($device.state.deviceErrorCode) $($device.state.deviceErrorName)"
            if ($device.state.deviceImportStatus -eq "complete") {
                $successCount = $successCount + 1
            }
        }
        Write-Host "$successCount devices imported successfully. Elapsed time to complete import: $importSeconds seconds"
        
        # Wait until the devices can be found in Intune (should sync automatically)
        $syncStart = Get-Date
        $processingCount = 1
        while ($processingCount -gt 0) {
            $autopilotDevices = @()
            $processingCount = 0
            $current | ForEach-Object {
                if ($device.state.deviceImportStatus -eq "complete") {
                    $device = Get-AutopilotDevice -id $_.state.deviceRegistrationId
                    if (-not $device) {
                        $processingCount = $processingCount + 1
                    }
                    $autopilotDevices += $device
                }    
            }
            $deviceCount = $autopilotDevices.Length
            Write-Host "Waiting for $processingCount of $deviceCount to be synced"
            if ($processingCount -gt 0) {
                Start-Sleep 30
            }
        }
        $syncDuration = (Get-Date) - $syncStart
        $syncSeconds = [Math]::Ceiling($syncDuration.TotalSeconds)
        Write-Host "All devices synced. Elapsed time to complete sync: $syncSeconds seconds"

        # Cleanup by Thiago Beier https://twitter.com/thiagobeier https://www.linkedin.com/in/tbeier/
        Get-AutopilotImportedDevice | Where-Object { $_.serialnumber -eq "$serial" } | ForEach-Object { Remove-AutopilotImportedDevice -id $_.id }
        # Invoke AutopilotSync (When windows autopilot devices GroupTag are updated // changing windows autopilot deployment profiles)
        try {
            Invoke-AutopilotSync -ErrorAction Stop
        }
        catch {
            Write-Host "$($_.exception.message)"
            Write-Host "An error occurred. Waiting for 12,5 minutes before retrying..."
            Start-Sleep -Seconds 750
            Invoke-AutopilotSync
        }

        # Add the device to the specified AAD group
        # Add the device to the specified AAD group
        if ($AddToGroup) {
            foreach ($ADGroup in $AddToGroup) {
                $aadGroup = Get-MgGroup -Filter "DisplayName eq '$ADGroup'"
                if ($aadGroup) {
                    $autopilotDevices | ForEach-Object {
                        $uri = "https://graph.microsoft.com/beta/devices?`$filter=deviceId eq '" + $_.azureActiveDirectoryDeviceId + "'"
                        $aadDevice = (Invoke-MgGraphRequest -Uri $uri -Method GET -OutputType PSObject -SkipHttpErrorCheck).value
                        if ($aadDevice) {
                            Write-Host "Adding device $($aadDevice.displayName) to group $ADGroup"
                            New-MgGroupMember -GroupId $aadGroup.Id -DirectoryObjectId $aadDevice.id
                        }
                        else {
                            Write-Error "Unable to find Azure AD device with ID $($aadDevice.deviceId)"
                        }
                    }
                    Write-Host "Added devices to group '$ADGroup' ($($aadGroup.Id))"
                }
                else {
                    Write-Error "Unable to find group $ADGroup"
                }
            }
        } #to deal with the array

        # Assign the computer name
        if ($AssignedComputerName -ne "") {
            $autopilotDevices | ForEach-Object {
                Set-AutopilotDevice -id $_.Id -displayName $AssignedComputerName
            }
        }

        # Wait for assignment (if specified)
        if ($Assign) {
            $assignStart = Get-Date
            $processingCount = 1
            while ($processingCount -gt 0) {
                $processingCount = 0
                $autopilotDevices | ForEach-Object {
                    $device = Get-AutopilotDevice -id $_.id -expand
                    if (-not ($device.deploymentProfileAssignmentStatus.StartsWith("assigned"))) {
                        $processingCount = $processingCount + 1
                    }
                }
                $deviceCount = $autopilotDevices.Length
                Write-Host "Waiting for $processingCount of $deviceCount to be assigned"
                if ($processingCount -gt 0) {
                    Start-Sleep 30
                }    
            }
            $assignDuration = (Get-Date) - $assignStart
            $assignSeconds = [Math]::Ceiling($assignDuration.TotalSeconds)
            Write-Host "Profiles assigned to all devices. Elapsed time to complete assignment: $assignSeconds seconds"    
            if ($Reboot) {
                Restart-Computer -Force
            }
            if ($Wipe) {
                $deviceserial = $serial
                ##Find device ID
                $deviceuri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$serial'"
                $deviceid = (Invoke-MgGraphRequest -Uri $deviceuri -Method GET -OutputType PSObject -SkipHttpErrorCheck).value.id
                Write-Host "Sending a wipe to $deviceid"
                ##Send a wipe
                $wipeuri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$deviceid/wipe"
                $wipebody = @{
                    keepEnrollmentData = $false
                    keepUserData       = $false
                }
                Invoke-MgGraphRequest -Uri $wipeuri -Method POST -Body $wipebody -ContentType "application/json"
                Write-Host "Wipe sent to $deviceid"
            }
            if ($Sysprep) {
                ##Send a sysprep
                Start-Process -NoNewWindow -FilePath "C:\windows\system32\sysprep\sysprep.exe" -ArgumentList "/oobe /reboot /quiet"
                Write-Host "Sysprep executed"
            }
            if ($preprov) {
                ##Create directory in %temp%
                $path = $env:TEMP + "\preprov"
                New-Item -Path $path -ItemType Directory
                $uri = "https://github.com/andrew-s-taylor/WindowsAutopilotInfo/raw/main/windowskey-autoit.exe"
                ##Download it
                $output = "$path\windowskey-autoit.exe"
                Invoke-WebRequest -Uri $uri -OutFile $output -UseBasicParsing
                Write-Host "File downloaded to $output"
                ##Run it
                &$output
                
            }
            if ($ChangePK -ne "") {
                # Run ChangePK.exe
                Write-Host "Starting ChangePK"
                Start-Process -NoNewWindow -Wait -FilePath "c:\windows\system32\changepk.exe" -ArgumentList "/ProductKey $ChangePK /NoUI /NoReboot"
                Restart-Computer -Force
            }

        }
    }
}
}
}
Write-SectionHeader "set time zone"
Set-TimeZone -Id "W. Europe Standard Time"
Set-Date -Date "08.02.2025 12:00:00"
$currentdate = Get-Date
Write-SectionHeader "$currentdate"


Write-SectionHeader "Executing CustomWindowsAutopilotInfo"
$AutopilotParams = @{
    Online = $true
    TenantId = '34ee6c5a-5795-41ae-941c-b722c4009fe4'
    AppId = '96d65efd-0885-4e0e-a05b-f7c37c37ae9d'
    AppSecret = 'rY58Q~8u.PnVo6nA4OlTKyM8CCGxcfkRhfwIIbD6'
    GroupTag = 'VM'
}
CustomWindowsAutopilotInfo @AutopilotParams

# Comment out after testing
# Write-Host ($Params | Out-String)


Write-SectionHeader "Executing CustomWindowsAutopilotInfo"
Start-Sleep -Seconds 3



Stop-Transcript | Out-Null
