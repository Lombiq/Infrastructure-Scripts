<#
.Synopsis
   Downloads every Container and their Blobs from an Azure Blob Storage.

.DESCRIPTION
   Downloads every Container and their Blobs from an Azure Blob Storage specified by a Connection String of a Web App.

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        Destination = "D:\Backup"
    }
    Save-AzureWebAppStorageContent @saveStorageContentParameters

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        Destination = "D:\Backup"
        ContainerWhiteList = @("media", "stuff")
    }
    Save-AzureWebAppStorageContent @saveStorageContentParameters

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        Destination = "D:\Backup"
        ContainerBlackList = @("stuffidontneed")
    }
    Save-AzureWebAppStorageContent @saveStorageContentParameters

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        Destination = "D:\Backup"
        ContainerBlackList = @("stuffidontneed")
        FolderWhiteList = @("usefulfolder")
    }
    Save-AzureWebAppStorageContent @saveStorageContentParameters

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        Destination = "D:\Backup"
        ContainerBlackList = @("stuffidontneed")
        FolderWhiteList = @("usefulfolder")
        FolderBlackList = @("uselessfolderintheusefulfolder")
        DestinationContainersAccessType = "Off"
    }
    Save-AzureWebAppStorageContent @saveStorageContentParameters
#>

Import-Module Az.Storage

function Save-AzureWebAppStorageContent
{
    [CmdletBinding()]
    [Alias('sasc')]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Resource Group the Web App is in.')]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Azure Web App. The script throws exception if' +
            "the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName,

        [Parameter(HelpMessage = 'The name of the Web App Slot.')]
        [string] $SlotName,

        [Parameter(Mandatory = $true, HelpMessage = 'The name of a connection string that identifies the Storage' +
            ' Account. The script will exit with error if there is no connection string defined with the name' +
            ' provided for the Production slot of the given Web App.')]
        [string] $ConnectionStringName,

        [Parameter(Mandatory = $true, HelpMessage = 'The path on the local machine where the files will be downloaded.')]
        [string] $Destination,

        [Parameter(HelpMessage = 'A list of names of Blob Containers to include. When valid values are provided,' +
            " it cancels out `"ContainerBlackList`".")]
        [string[]] $ContainerWhiteList = @(),

        [Parameter(HelpMessage = 'A list of names of Blob Containers to exclude. When valid values are provided for' +
            " `"ContainerWhiteList`", then `"ContainerBlackList`" is not taken into consideration.")]
        [string[]] $ContainerBlackList = @(),

        [Parameter(HelpMessage = "A list of folder names to include. Applied before `"FolderBlackList`".")]
        [string[]] $FolderWhiteList = @(),

        [Parameter(HelpMessage = "A list of folder names to exclude. Applied after `"FolderWhiteList`".")]
        [string[]] $FolderBlackList = @(),

        [Parameter(HelpMessage = 'The number of attempts for retrieving a specific blob. The default value is 3.')]
        [int] $RetryCount = 3
    )

    Process
    {
        $storageConnectionParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SlotName
            ConnectionStringName = $ConnectionStringName
        }
        $storageConnection = Get-AzureWebAppStorageConnection @storageConnectionParameters

        $storageContextParameters = @{
            StorageAccountName = $storageConnection.AccountName
            StorageAccountKey = $storageConnection.AccountKey
        }
        $storageContext = New-AzStorageContext @storageContextParameters

        $containerWhiteListValid = $ContainerWhiteList -and $ContainerWhiteList.Count -gt 0
        $containerBlackListValid = $ContainerBlackList -and $ContainerBlackList.Count -gt 0

        $containers = Get-AzStorageContainer -Context $storageContext |
            Where-Object {
            ((!$containerWhiteListValid -or ($containerWhiteListValid -and $ContainerWhiteList.Contains($PSItem.Name))) -and
                ($containerWhiteListValid -or (!$containerBlackListValid -or !$ContainerBlackList.Contains($PSItem.Name))))
            }

        $folderWhiteListValid = $FolderWhiteList -and $FolderWhiteList.Count -gt 0
        $folderBlackListValid = $FolderBlackList -and $FolderBlackList.Count -gt 0

        $illegalCharacters = @("`"", '*', ':', '<', '>', '?', '|')

        foreach ($container in $containers)
        {
            $containerPath = $Destination + '\' + $container.Name

            if (Test-Path $containerPath)
            {
                Remove-Item -Path $containerPath -Recurse -Force
            }

            $comparisonParameters = @{
                PassThru = $true
                IncludeEqual = $true
                ExcludeDifferent = $true
            }
            $blobs = $container | Get-AzStorageBlob |
                Where-Object {
                (!$folderWhiteListValid -or ($folderWhiteListValid -and
                    (Compare-Object $PSItem.Name.Split('/', [StringSplitOptions]::RemoveEmptyEntries) $FolderWhiteList @comparisonParameters))) -and
                (!$folderBlackListValid -or ($folderBlackListValid -and
                    (!(Compare-Object $PSItem.Name.Split('/', [StringSplitOptions]::RemoveEmptyEntries) $FolderBlackList @comparisonParameters))))
                }

            foreach ($blob in $blobs)
            {
                $retryCounter = 0
                $success = $false

                do
                {
                    try
                    {
                        $blobPath = $blob.Name

                        foreach ($character in $illegalCharacters)
                        {
                            $blobPath = $blobPath.Replace($character, '_')
                            $blobPath = $blobPath.Replace('/', '\')
                        }

                        $path = $containerPath + '\' + $blobPath

                        if (-not (Test-Path ($path)))
                        {
                            New-Item -ItemType Directory -Path (Split-Path -Path $path -Parent) -Force | Out-Null
                        }

                        $blobParameters = @{
                            Context = $storageContext
                            Container = $container.Name
                            Blob = $blob.Name
                            Destination = $path
                            ErrorAction = 'Stop'
                            Force = $true
                        }
                        Get-AzStorageBlobContent @blobParameters | Out-Null

                        Write-Output ("Downloaded `"" + $container.Name + '/' + $blob.Name + "`".")

                        $success = $true
                    }
                    catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException], [System.InvalidOperationException]
                    {
                        $retryCounter++
                    }
                    catch
                    {
                        throw
                    }
                }
                while ($retryCounter -le $RetryCount -and -not $success)

                if ($retryCounter -gt $RetryCount)
                {
                    Write-Error ("Failed to download the blob `"" + $container.Name + '/' + $blob.Name + "`"!")
                }
            }
        }
    }
}