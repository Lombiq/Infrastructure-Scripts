<#
.Synopsis
    Downloads every Container and their Blobs from an Azure Blob Storage.

.DESCRIPTION
    Downloads every Container and their Blobs from an Azure Blob Storage specified by a Connection String of a Web App.

.EXAMPLE
    $setStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        SourceConnectionStringName = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
    }
    Set-AzureWebAppStorageContentFromStorageWithAzCopy @setStorageContentParameters

.EXAMPLE
    $setStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        SourceConnectionStringName = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerIncludeList = @("media", "stuff")
    }
    Set-AzureWebAppStorageContentFromStorageWithAzCopy @setStorageContentParameters

.EXAMPLE
    $setStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        SourceConnectionStringName = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerIncludeList = @("media", "stuff")
        SasLifetimeMinutes = 10
    }
    Set-AzureWebAppStorageContentFromStorageWithAzCopy @setStorageContentParameters
#>

Import-Module Az.Storage

function Set-AzureWebAppStorageContentFromStorageWithAzCopy
{
    [CmdletBinding()]
    [Alias('sascsazc')]
    Param
    (
        [Alias('ResourceGroupName')]
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'You need to provide the name of the Resource Group the Source Web App is in.')]
        [string] $SourceResourceGroupName,

        [Alias('WebAppName')]
        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide the name of the Web App.')]
        [string] $SourceWebAppName,

        [Alias('SlotName')]
        [Parameter(HelpMessage = 'The name of the Source Web App slot.')]
        [string] $SourceSlotName,

        [Alias('ConnectionStringName')]
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'You need to provide a connection string name for the source Storage Account.')]
        [string] $SourceConnectionStringName,

        [Parameter(HelpMessage = 'The name of the Destination Resource Group if it differs from the Source.')]
        [string] $DestinationResourceGroupName = $SourceResourceGroupName,

        [Parameter(HelpMessage = 'The name of the Destination Web App if it differs from the Source.')]
        [string] $DestinationWebAppName = $SourceWebAppName,

        [Parameter(HelpMessage = 'The name of the Destination Web App Slot if it differs from the Source.')]
        [string] $DestinationSlotName = $SourceSlotName,

        [Parameter(HelpMessage = 'The name of the Destination Connection String if it differs from the Source.')]
        [string] $DestinationConnectionStringName = $SourceConnectionStringName,

        [Parameter(HelpMessage = 'A list of names of Blob Containers to include.')]
        [string[]] $ContainerIncludeList = @(),

        [Parameter(HelpMessage = 'Determines whether the destination containers should be deleted and re-created ' +
            'before copying the blobs from the source containers.')]
        [bool] $RemoveExtraFilesOnDestination = $true,

        [Parameter(HelpMessage = 'The number of minutes defining how long the generated Shared Access Signatures ' +
            '(https://learn.microsoft.com/en-us/azure/storage/common/storage-sas-overview) used for blob storage ' +
            'operations are valid for. Default value is 5.')]
        [int] $SasLifetimeMinutes = 5,

        [Parameter(HelpMessage = 'Overrides the access level of the containers, but only affects those that are (re-)created.')]
        [Microsoft.WindowsAzure.Storage.Blob.BlobContainerPublicAccessType] $DestinationContainersAccessType,

        [Parameter(HelpMessage = 'Adds a prefix to the name of the containers, but only affects those that are (re-)created.')]
        [string] $DestinationContainerNamePrefix = '',

        [Parameter(HelpMessage = 'Adds a suffix to the name of the containers, but only affects those that are (re-)created.')]
        [string] $DestinationContainerNameSuffix = ''
    )

    Process
    {
        # Check if azcopy command is available.
        $azcopy = Get-Command azcopy -ErrorAction SilentlyContinue
        if ($null -eq $azcopy)
        {
            throw 'AzCopy executable not found! You can use "Set-AzureWebAppStorageContentFromStorage" instead.'
        }

        # Grab the source storage account's connection details.
        $sourceStorageConnectionParameters = @{
            ResourceGroupName = $SourceResourceGroupName
            WebAppName = $SourceWebAppName
            SlotName = $SourceSlotName
            ConnectionStringName = $SourceConnectionStringName
        }
        $sourceStorageConnection = Get-AzureWebAppStorageConnection @sourceStorageConnectionParameters

        # Grab the destination storage account's connection details.
        $destinationStorageConnectionParameters = @{
            ResourceGroupName = $DestinationResourceGroupName
            WebAppName = $DestinationWebAppName
            SlotName = $DestinationSlotName
            ConnectionStringName = $DestinationConnectionStringName
        }
        $destinationStorageConnection = Get-AzureWebAppStorageConnection @destinationStorageConnectionParameters

        # Stop if the source and destination storage accounts are the same. We could improve this by allowing when a
        # destination container name prefix and/or suffix is applied.
        if ($sourceStorageConnection.AccountName -eq $destinationStorageConnection.AccountName)
        {
            throw 'The destination Storage Account can not be the same as the source!'
        }

        # Construct the source storage context.
        $sourceStorageContextParameters = @{
            StorageAccountName = $sourceStorageConnection.AccountName
            StorageAccountKey = $sourceStorageConnection.AccountKey
        }
        $sourceStorageContext = New-AzStorageContext @sourceStorageContextParameters

        # Construct the destination storage context.
        $destinationStorageContextParameters = @{
            StorageAccountName = $destinationStorageConnection.AccountName
            StorageAccountKey = $destinationStorageConnection.AccountKey
        }
        $destinationStorageContext = New-AzStorageContext @destinationStorageContextParameters

        # Preparing to validate the list of source containers.
        $containerIncludeListValid = $ContainerIncludeList -and $ContainerIncludeList.Count -gt 0
        $sourceContainers = $sourceStorageContext | Get-AzStorageContainer |
            Where-Object { !$containerIncludeListValid -or ($containerIncludeListValid -and $ContainerIncludeList.Contains($PSItem.Name)) }
        $sourceContainerNames = $sourceContainers | Select-Object -ExpandProperty 'Name'

        # Throwing error if none of the source containers exist.
        if ($null -eq $sourceContainers)
        {
            throw 'Couldn''t find any of the specified containers in the source Storage Account!'
        }
        # Throwing error if some of the source containers don't exist.
        elseif ($containerIncludeListValid)
        {
            $notFoundSourceContainerNames = $ContainerIncludeList | Where-Object { $sourceContainerNames -notcontains $PSItem }

            if ($null -ne $notFoundSourceContainerNames)
            {
                throw "Some of the containers in the source Storage Account were not found: $($notFoundSourceContainerNames -join ', ')!"
            }
        }

        # Iterating through the source containers.
        foreach ($sourceContainer in $sourceContainers)
        {
            # Constructing the destination container name.
            $destinationContainerName = $DestinationContainerNamePrefix + $sourceContainer.Name + $DestinationContainerNameSuffix

            # Creating the container on the destination account if it doesn't exist yet.
            if ($null -eq (Get-AzStorageContainer -Context $destinationStorageContext | Where-Object { $PSItem.Name -eq $destinationContainerName }))
            {
                $containerAccessType = $DestinationContainersAccessType
                if ($null -eq $containerAccessType)
                {
                    $containerAccessType = $sourceContainer.PublicAccess
                }

                $newContainerParameters = @{
                    Context = $destinationStorageContext
                    Permission = $containerAccessType
                    Name = $destinationContainerName
                    ErrorAction = 'Stop'
                }
                New-AzStorageContainer @newContainerParameters
            }

            # Requesting access token for the destination container and constructing the copy URL.
            $destinationAccessToken = New-AzStorageAccountSASToken -Context $destinationStorageContext -Service Blob -ResourceType 'Container,Object' -Permission 'lrwd' -ExpiryTime (Get-Date).AddMinutes($SasLifetimeMinutes) -Protocol HttpsOnly
            if ($destinationAccessToken -notlike '?*') { $destinationAccessToken = "?$destinationAccessToken" }
            $destinationContainerUrl = "https://$($destinationStorageConnection.AccountName).blob.core.windows.net/$($destinationContainerName + $destinationAccessToken)"

            # Clearing out the destination container, if necessary.
            if ($RemoveExtraFilesOnDestination)
            {
                azcopy remove $destinationContainerUrl --recursive=true
            }

            # Requesting access token for the source container and constructing the copy URL.
            $sourceAccessToken = New-AzStorageAccountSASToken -Context $sourceStorageContext -Service Blob -ResourceType 'Container,Object' -Permission 'lr' -ExpiryTime (Get-Date).AddMinutes($SasLifetimeMinutes) -Protocol HttpsOnly
            if ($sourceAccessToken -notlike '?*') { $sourceAccessToken = "?$sourceAccessToken" }
            $sourceContainerUrl = "https://$($sourceStorageConnection.AccountName).blob.core.windows.net/$($sourceContainer.Name + $sourceAccessToken)"

            # This requires the Read role assignment on the Storage Account, whereas Storage Blob Data Contributor is
            # sufficient for CRUD operations on blobs.
            $preserveAccessTierOnDestination = $null -ne (Get-AzStorageAccount -ResourceGroupName $DestinationResourceGroupName -Name $destinationStorageConnection.AccountName).AccessTier

            # And finally, the actual copy operation.
            # WARNING: The first two unnamed parameters are the source and the destination in this order.
            azcopy copy $sourceContainerUrl $destinationContainerUrl --recursive=true --s2s-preserve-access-tier=$preserveAccessTierOnDestination
        }
    }
}
