<#
.Synopsis
   Downloads every Container and their Blobs from an Azure Blob Storage.

.DESCRIPTION
   Downloads every Container and their Blobs from an Azure Blob Storage specified by a Connection String of a Web App.

.EXAMPLE
   Set-AzureWebAppStorageContentFromStorage -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -SourceConnectionStringName "SourceStorage" -DestinationConnectionStringName "DestinationStorage"

.EXAMPLE
   Set-AzureWebAppStorageContentFromStorage -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -SourceConnectionStringName "SourceStorage" -DestinationConnectionStringName "DestinationStorage" -ContainerWhiteList @("media", "stuff")

.EXAMPLE
   Set-AzureWebAppStorageContentFromStorage -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -SourceConnectionStringName "SourceStorage" -DestinationConnectionStringName "DestinationStorage" -ContainerBlackList @("stuffidontneed")

.EXAMPLE
   Set-AzureWebAppStorageContentFromStorage -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -SourceConnectionStringName "SourceStorage" -DestinationConnectionStringName "DestinationStorage" -ContainerBlackList @("stuffidontneed") -FolderWhiteList @("usefulfolder")

.EXAMPLE
   Set-AzureWebAppStorageContentFromStorage -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -SourceConnectionStringName "SourceStorage" -DestinationConnectionStringName "DestinationStorage" -ContainerBlackList @("stuffidontneed") -FolderWhiteList @("usefulfolder") -FolderBlackList @("uselessfolderintheusefulfolder")
#>


Import-Module Az.Storage


function Set-AzureWebAppStorageContentFromStorage
{
    [CmdletBinding()]
    [Alias("sascs")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the source Storage Account. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $SourceConnectionStringName = $(throw "You need to provide a connection string name for the source Storage Account."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the destination Storage Account. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $DestinationConnectionStringName = $(throw "You need to provide a connection string name for the destination Storage Account."),

        [Parameter(HelpMessage = "A list of names of Blob Containers to include. When valid values are provided, it cancels out `"ContainerBlackList`".")]
        [string[]] $ContainerWhiteList = @(),

        [Parameter(HelpMessage = "A list of names of Blob Containers to exclude. When valid values are provided for `"ContainerWhiteList`", then `"ContainerBlackList`" is not taken into consideration.")]
        [string[]] $ContainerBlackList = @(),

        [Parameter(HelpMessage = "A list of folder names to include. Applied before `"FolderBlackList`".")]
        [string[]] $FolderWhiteList = @(),

        [Parameter(HelpMessage = "A list of folder names to exclude. Applied after `"FolderWhiteList`".")]
        [string[]] $FolderBlackList = @(),

        [Parameter(HelpMessage = "Determines whether the destination containers should be deleted and re-created before copying the blobs from the source containers.")]
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
        $sourceStorageConnection = Get-AzureWebAppStorageConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $SourceConnectionStringName
        $destinationStorageConnection = Get-AzureWebAppStorageConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $DestinationConnectionStringName

        if ($sourceStorageConnection.AccountName -eq $destinationStorageConnection.AccountName)
        {
            throw ("The destination Storage Account can not be the same as the source!")
        }

        $sourceStorageContext = New-AzStorageContext -StorageAccountName $sourceStorageConnection.AccountName -StorageAccountKey $sourceStorageConnection.AccountKey
        $destinationStorageContext = New-AzStorageContext -StorageAccountName $destinationStorageConnection.AccountName -StorageAccountKey $destinationStorageConnection.AccountKey

        $containerWhiteListValid = $ContainerWhiteList -and $ContainerWhiteList.Count -gt 0
        $containerBlackListValid = $ContainerBlackList -and $ContainerBlackList.Count -gt 0
        
        $sourceContainers = Get-AzStorageContainer -Context $sourceStorageContext `
            | Where-Object `
            { `
                ((!$containerWhiteListValid -or ($containerWhiteListValid -and $ContainerWhiteList.Contains($PSItem.Name))) `
                -and ($containerWhiteListValid -or (!$containerBlackListValid -or !$ContainerBlackList.Contains($PSItem.Name)))) `
            }

        # Removing containers on the destination, if necessary.
        if ($RemoveExtraFilesOnDestination)
        {
            Get-AzStorageContainer -Context $destinationStorageContext | Where-Object { ($sourceContainers | Select-Object -ExpandProperty "Name").Contains($PSItem.Name) } | Remove-AzStorageContainer -Force
        }

        $folderWhiteListValid = $FolderWhiteList -and $FolderWhiteList.Count -gt 0
        $folderBlackListValid = $FolderBlackList -and $FolderBlackList.Count -gt 0

        foreach ($sourceContainer in $sourceContainers)
        {
            $destinationContainerName = $DestinationContainerNamePrefix + $sourceContainer.Name + $DestinationContainerNameSuffix

            # Creating the container on the destination if it was removed or it doesn't exist yet.
            if ($RemoveExtraFilesOnDestination -or (Get-AzStorageContainer -Context $destinationStorageContext | Where-Object { $_.Name -eq $destinationContainerName }) -eq $null)
            {
                $containerCreated = $false

                do
                {
                    try
                    {
                        $containerAccessType = $DestinationContainersAccessType
                        if ($containerAccessType -eq $null)
                        {
                            $containerAccessType = $sourceContainer.PublicAccess
                        }

                        
                        $destinationContainer = New-AzStorageContainer -Context $destinationStorageContext -Permission $containerAccessType -Name $destinationContainerName -ErrorAction Stop

                        $containerCreated = $true
                    }
                    catch [System.Net.WebException],[System.Exception] # Catching [Microsoft.WindowsAzure.Storage.StorageException] is not sufficient for some reason...
                    {
                        Write-Warning ("Error during re-creating the container `"" + $sourceContainer.Name + "`". Retrying in a few seconds...`n" + $_.Exception.Message + "`n")
                        Start-Sleep 5
                    }
                }
                while (!$containerCreated)
            }

            foreach ($sourceBlob in $sourceContainer | Get-AzStorageBlob)
            {
                $blobNameElements = $sourceBlob.Name.Split("/", [StringSplitOptions]::RemoveEmptyEntries)

                if ((!$folderWhiteListValid -or ($folderWhiteListValid -and (Compare-Object $blobNameElements $FolderWhiteList -PassThru -IncludeEqual -ExcludeDifferent))) `
                    -and (!$folderBlackListValid -or ($folderBlackListValid -and (!(Compare-Object $blobNameElements $FolderBlackList -PassThru -IncludeEqual -ExcludeDifferent)))))
                {
                    Start-AzStorageBlobCopy -Context $sourceStorageContext -SrcContainer $sourceContainer.Name -SrcBlob $sourceBlob.Name `
                        -DestContext $destinationStorageContext -DestContainer $destinationContainerName -DestBlob $sourceBlob.Name -Force | Out-Null

                    Write-Host ("Copied `"" + $sourceContainer.Name + "/" + $sourceBlob.Name + "`" to `"$destinationContainerName`".")
                }
            }
        }
    }
}