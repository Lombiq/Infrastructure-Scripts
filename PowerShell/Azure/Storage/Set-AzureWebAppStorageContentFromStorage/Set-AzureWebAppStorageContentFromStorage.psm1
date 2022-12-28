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
    Set-AzureWebAppStorageContentFromStorage @setStorageContentParameters

.EXAMPLE
    $setStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        SourceConnectionStringName = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerWhiteList = @("media", "stuff")
    }
    Set-AzureWebAppStorageContentFromStorage @setStorageContentParameters

.EXAMPLE
    $setStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        SourceConnectionStringName = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerBlackList = @("stuffidontneed")
    }
    Set-AzureWebAppStorageContentFromStorage @setStorageContentParameters

.EXAMPLE
    $setStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        SourceConnectionStringName = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerBlackList = @("stuffidontneed")
        FolderWhiteList = @("usefulfolder")
    }
    Set-AzureWebAppStorageContentFromStorage @setStorageContentParameters

.EXAMPLE
    $setStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        SourceConnectionStringName = "SourceStorage"
        DestinationConnectionStringName = "DestinationStorage"
        ContainerBlackList = @("stuffidontneed")
        FolderWhiteList = @("usefulfolder")
        FolderBlackList = @("uselessfolderintheusefulfolder")
    }
    Set-AzureWebAppStorageContentFromStorage @setStorageContentParameters
#>

Import-Module Az.Storage

function Set-AzureWebAppStorageContentFromStorage
{
    [CmdletBinding()]
    [Alias("sascs")]
    Param
    (
        [Alias("ResourceGroupName")]
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide the name of the Resource Group the Source Web App is in.")]
        [string] $SourceResourceGroupName,

        [Alias("WebAppName")]
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $SourceWebAppName,

        [Alias("SlotName")]
        [Parameter(HelpMessage = "The name of the Source Web App slot.")]
        [string] $SourceSlotName,

        [Alias("ConnectionStringName")]
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide a connection string name for the source Storage Account.")]
        [string] $SourceConnectionStringName,

        [Parameter(HelpMessage = "The name of the Destination Resource Group if it differs from the Source.")]
        [string] $DestinationResourceGroupName = $SourceResourceGroupName,

        [Parameter(HelpMessage = "The name of the Destination Web App if it differs from the Source.")]
        [string] $DestinationWebAppName = $SourceWebAppName,

        [Parameter(HelpMessage = "The name of the Destination Web App Slot if it differs from the Source.")]
        [string] $DestinationSlotName = $SourceSlotName,

        [Parameter(HelpMessage = "The name of the Destination Connection String if it differs from the Source.")]
        [string] $DestinationConnectionStringName = $SourceConnectionStringName,

        [Parameter(HelpMessage = "A list of names of Blob Containers to include. When valid values are provided, " +
            "it cancels out `"ContainerBlackList`".")]
        [string[]] $ContainerWhiteList = @(),

        [Parameter(HelpMessage = "A list of names of Blob Containers to exclude. When valid values are provided " +
            "for `"ContainerWhiteList`", then `"ContainerBlackList`" is not taken into consideration.")]
        [string[]] $ContainerBlackList = @(),

        [Parameter(HelpMessage = "A list of folder names to include. Applied before `"FolderBlackList`".")]
        [string[]] $FolderWhiteList = @(),

        [Parameter(HelpMessage = "A list of folder names to exclude. Applied after `"FolderWhiteList`".")]
        [string[]] $FolderBlackList = @(),

        [Parameter(HelpMessage = "Determines whether the destination containers should be deleted and re-created " +
            "before copying the blobs from the source containers.")]
        [bool] $RemoveExtraFilesOnDestination = $true,

        [Parameter(HelpMessage = "Overrides the access level of the containers, but only affects those that are (re-)created.")]
        [Microsoft.WindowsAzure.Storage.Blob.BlobContainerPublicAccessType] $DestinationContainersAccessType,

        [Parameter(HelpMessage = "Adds a prefix to the name of the containers, but only affects those that are (re-)created.")]
        [string] $DestinationContainerNamePrefix = "",

        [Parameter(HelpMessage = "Adds a suffix to the name of the containers, but only affects those that are (re-)created.")]
        [string] $DestinationContainerNameSuffix = ""
    )

    Process
    {
        $sourceStorageConnectionParameters = @{
            ResourceGroupName = $SourceResourceGroupName
            WebAppName = $SourceWebAppName
            SlotName = $SourceSlotName
            ConnectionStringName = $SourceConnectionStringName
        }
        $sourceStorageConnection = Get-AzureWebAppStorageConnection @sourceStorageConnectionParameters

        $destinationStorageConnectionParameters = @{
            ResourceGroupName = $DestinationResourceGroupName
            WebAppName = $DestinationWebAppName
            SlotName = $DestinationSlotName
            ConnectionStringName = $DestinationConnectionStringName
        }
        $destinationStorageConnection = Get-AzureWebAppStorageConnection @destinationStorageConnectionParameters

        if ($sourceStorageConnection.AccountName -eq $destinationStorageConnection.AccountName)
        {
            throw ("The destination Storage Account can not be the same as the source!")
        }

        $sourceStorageContextParameters = @{
            StorageAccountName = $sourceStorageConnection.AccountName
            StorageAccountKey = $sourceStorageConnection.AccountKey
        }
        $sourceStorageContext = New-AzStorageContext @sourceStorageContextParameters

        $destinationStorageContextParameters = @{
            StorageAccountName = $destinationStorageConnection.AccountName
            StorageAccountKey = $destinationStorageConnection.AccountKey
        }
        $destinationStorageContext = New-AzStorageContext @destinationStorageContextParameters

        $containerWhiteListValid = $ContainerWhiteList -and $ContainerWhiteList.Count -gt 0
        $containerBlackListValid = $ContainerBlackList -and $ContainerBlackList.Count -gt 0

        $sourceContainers = Get-AzStorageContainer -Context $sourceStorageContext |
            Where-Object {
                ((!$containerWhiteListValid -or ($containerWhiteListValid -and $ContainerWhiteList.Contains($PSItem.Name))) -and
                ($containerWhiteListValid -or (!$containerBlackListValid -or !$ContainerBlackList.Contains($PSItem.Name))))
            }
        $sourceContainerNames = $sourceContainers | Select-Object -ExpandProperty "Name"

        if ($null -eq $sourceContainers)
        {
            throw "Couldn't find any of the specified containers in the source Storage Account!"
        }
        elseif ($containerWhiteListValid)
        {
            $notFoundSourceContainerNames = $ContainerWhiteList | Where-Object { $sourceContainerNames -notcontains $PSItem }

            if ($null -ne $notFoundSourceContainerNames)
            {
                throw "Some of the containers in the source Storage Account were not found: $($notFoundSourceContainerNames -join ", ")!"
            }
        }

        # Removing containers on the destination, if necessary.
        if ($RemoveExtraFilesOnDestination)
        {
            Get-AzStorageContainer -Context $destinationStorageContext |
                Where-Object { $sourceContainerNames.Contains($PSItem.Name) } |
                Remove-AzStorageContainer -Force
        }

        $folderWhiteListValid = $FolderWhiteList -and $FolderWhiteList.Count -gt 0
        $folderBlackListValid = $FolderBlackList -and $FolderBlackList.Count -gt 0

        foreach ($sourceContainer in $sourceContainers)
        {
            $destinationContainerName = $DestinationContainerNamePrefix + $sourceContainer.Name + $DestinationContainerNameSuffix

            # Creating the container on the destination if it was removed or it doesn't exist yet.
            if ($RemoveExtraFilesOnDestination -or
                $null -eq (Get-AzStorageContainer -Context $destinationStorageContext | Where-Object { $PSItem.Name -eq $destinationContainerName }))
            {
                $containerCreated = $false

                do
                {
                    try
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
                            ErrorAction = "Stop"
                        }
                        New-AzStorageContainer @newContainerParameters

                        $containerCreated = $true
                    }
                    # Catching [Microsoft.WindowsAzure.Storage.StorageException] is not sufficient for some reason...
                    catch [System.Net.WebException], [System.Exception]
                    {
                        Write-Warning ("Error during re-creating the container `"$($sourceContainer.Name)`". Retrying in a few seconds...`n" +
                            $PSItem.Exception.Message + "`n")

                        Start-Sleep 5
                    }
                }
                while (!$containerCreated)
            }

            Write-Output ("`n*****`nCopying blobs from `"$($sourceContainer.Name)`" to `"$destinationContainerName`"`n*****")

            foreach ($sourceBlob in $sourceContainer | Get-AzStorageBlob)
            {
                $blobNameElements = $sourceBlob.Name.Split("/", [StringSplitOptions]::RemoveEmptyEntries)
                $comparisonParameters = @{
                    PassThru = $true
                    IncludeEqual = $true
                    ExcludeDifferent = $true
                }

                if ((!$folderWhiteListValid -or
                        ($folderWhiteListValid -and (Compare-Object $blobNameElements $FolderWhiteList @comparisonParameters))) -and
                    (!$folderBlackListValid -or
                        ($folderBlackListValid -and (!(Compare-Object $blobNameElements $FolderBlackList @comparisonParameters)))))
                {
                    $copyParameters = @{
                        Context = $sourceStorageContext
                        SrcContainer = $sourceContainer.Name
                        SrcBlob = $sourceBlob.Name
                        DestContext = $destinationStorageContext
                        DestContainer = $destinationContainerName
                        DestBlob = $sourceBlob.Name
                        Force = $true
                    }
                    Start-AzStorageBlobCopy @copyParameters | Out-Null

                    Write-Output $sourceBlob.Name
                }
            }
        }
    }
}