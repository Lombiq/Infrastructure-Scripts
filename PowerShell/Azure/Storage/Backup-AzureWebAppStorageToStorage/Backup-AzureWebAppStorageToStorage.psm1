<#
.Synopsis
    Creates a backup of a specified Storage Account to another Storage Account.

.DESCRIPTION
    Creates a backup of a specified Storage Account to another Storage Account, specified by their connection string names found on a Web App.

.EXAMPLE
    Backup-AzureWebAppStorageToStorage @{
        ResourceGroupName               = "CoolStuffHere"
        WebAppName                      = "NiceApp"
        SourceConnectionStringName      = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
    }

.EXAMPLE
    Backup-AzureWebAppStorageToStorage @{
        ResourceGroupName               = "CoolStuffHere"
        WebAppName                      = "NiceApp"
        SourceConnectionStringName      = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerWhiteList              = @("media", "stuff")
    }

.EXAMPLE
    Backup-AzureWebAppStorageToStorage @{
        ResourceGroupName               = "CoolStuffHere"
        WebAppName                      = "NiceApp"
        SourceConnectionStringName      = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerBlackList              = @("stuffidontneed")
    }

.EXAMPLE
    Backup-AzureWebAppStorageToStorage @{
        ResourceGroupName               = "CoolStuffHere"
        WebAppName                      = "NiceApp"
        SourceConnectionStringName      = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerBlackList              = @("stuffidontneed")
        FolderWhiteList                 = @("usefulfolder")
    }

.EXAMPLE
    Backup-AzureWebAppStorageToStorage @{
        ResourceGroupName               = "CoolStuffHere"
        WebAppName                      = "NiceApp"
        SourceConnectionStringName      = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerBlackList              = @("stuffidontneed")
        FolderWhiteList                 = @("usefulfolder")
        FolderBlackList                 = @("uselessfolderintheusefulfolder")
        DestinationContainersAccessType = "Off"
    }
#>

Import-Module Az.Storage

function Backup-AzureWebAppStorageToStorage
{
    [CmdletBinding()]
    [Alias("basts")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the source Storage Account. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $SourceConnectionStringName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the destination Storage Account. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $DestinationConnectionStringName,

        [Parameter(HelpMessage = "A list of names of Blob Containers to include. When valid values are provided, it cancels out `"ContainerBlackList`".")]
        [string[]] $ContainerWhiteList = @(),

        [Parameter(HelpMessage = "A list of names of Blob Containers to exclude. When valid values are provided for `"ContainerWhiteList`", then `"ContainerBlackList`" is not taken into consideration.")]
        [string[]] $ContainerBlackList = @(),

        [Parameter(HelpMessage = "A list of folder names to include. Applied before `"FolderBlackList`".")]
        [string[]] $FolderWhiteList = @(),

        [Parameter(HelpMessage = "A list of folder names to exclude. Applied after `"FolderWhiteList`".")]
        [string[]] $FolderBlackList = @(),

        [Parameter(HelpMessage = "Overrides the access level of the containers, but only affects those that are (re-)created.")]
        [Microsoft.WindowsAzure.Storage.Blob.BlobContainerPublicAccessType]
        $DestinationContainersAccessType = [Microsoft.WindowsAzure.Storage.Blob.BlobContainerPublicAccessType]::Off,

        [Parameter(HelpMessage = "The number of days to keep storage backup containers for, with respect to the LastModifiedDate property.")]
        [int] $RemoveBackupContainersOlderThanDays = 0
    )

    Process
    {
        $now = (Get-Date).ToUniversalTime()

        if ($RemoveBackupContainersOlderThanDays -gt 0)
        {
            $destinationStorageConnection = Get-AzureWebAppStorageConnection @{
                ResourceGroupName    = $ResourceGroupName
                WebAppName           = $WebAppName
                ConnectionStringName = $DestinationConnectionStringName
            }
            $destinationStorageContext = New-AzStorageContext @{
                StorageAccountName = $destinationStorageConnection.AccountName
                StorageAccountKey  = $destinationStorageConnection.AccountKey
            }
            Write-Warning ("Removing backup storage containers older than $RemoveBackupContainersOlderThanDays days!")
            Get-AzStorageContainer -Context $destinationStorageContext |
                Where-Object { (New-TimeSpan -Start $PSItem.LastModified.UtcDateTime -End $now).Days -gt $RemoveBackupContainersOlderThanDays } |
                Remove-AzStorageContainer -Force
        }

        $sourceStorageConnection = Get-AzureWebAppStorageConnection @{
            ResourceGroupName    = $ResourceGroupName
            WebAppName           = $WebAppName
            ConnectionStringName = $SourceConnectionStringName
        }
        $containerNamePrefix = $sourceStorageConnection.AccountName + "-" + $now.ToString("yyyy-MM-dd-HH-mm-ss") + "-"
      
        Set-AzureWebAppStorageContentFromStorage @{
            ResourceGroupName               = $ResourceGroupName
            WebAppName                      = $WebAppName
            SourceConnectionStringName      = $SourceConnectionStringName
            DestinationConnectionStringName = $DestinationConnectionStringName
            ContainerWhiteList              = $ContainerWhiteList
            ContainerBlackList              = $ContainerBlackList
            FolderWhiteList                 = $FolderWhiteList
            FolderBlackList                 = $FolderBlackList
            RemoveExtraFilesOnDestination   = $true
            DestinationContainersAccessType = $DestinationContainersAccessType
            DestinationContainerNamePrefix  = $containerNamePrefix
        }
    }
}