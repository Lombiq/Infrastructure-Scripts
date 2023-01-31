<#
.Synopsis
    Copies each blob in a container between two Storage Accounts.

.DESCRIPTION
    Copies each blob of a container defined by its name the name of an Azure Blob Storage specified by a Connection
    String of a Web App to another container.

.EXAMPLE
    $copyParameters = @{
        ResourceGroupName = "HelloAzure"
        WebAppName = "ThisWebApp"
        SourceConnectionStringName = "Lombiq.Hosting.Azure.Backup.StorageConnectionString"
        SourceContainerName = "backup"
        DestinationConnectionStringName = "Orchard.Azure.Media.StorageConnectionString"
        DestinationContainerName = "production"
    }
    Invoke-AzureWebAppStorageContainerCopy @copyParameters

.EXAMPLE
    $copyParameters = @{
        ResourceGroupName = "HelloAzure"
        WebAppName = "ThisWebApp"
        SourceConnectionStringName = "Lombiq.Hosting.Azure.Backup.StorageConnectionString"
        SourceContainerName = "backup"
        DestinationConnectionStringName = "Orchard.Azure.Media.StorageConnectionString"
        DestinationContainerName = "production"
        Force = $true
    }
    Invoke-AzureWebAppStorageContainerCopy @copyParameters
#>

Import-Module Az.Storage

function Invoke-AzureWebAppStorageContainerCopy
{
    [CmdletBinding()]
    [Alias('iawscc')]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Resource Group the Web App is in.')]
        [string] $ResourceGroupName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The name of a connection string that identifies the source Storage Account.')]
        [string] $SourceConnectionStringName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The name of the container to copy, under the source Storage Account.')]
        [string] $SourceContainerName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The name of a connection string that identifies the destination Storage Account.')]
        [string] $DestinationConnectionStringName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The name of the container to copy, under the source Storage Account.')]
        [string] $DestinationContainerName,

        [switch] $Force
    )

    Process
    {
        if ($SourceConnectionStringName -eq $DestinationConnectionStringName -and
            $SourceContainerName -eq $DestinationContainerName)
        {
            throw ('The destination container cannot be the same as the source!')
        }

        $sourceStorageConnectionParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            ConnectionStringName = $SourceConnectionStringName
        }
        $sourceStorageConnection = Get-AzureWebAppStorageConnection @sourceStorageConnectionParameters

        $sourceStorageContextParameters = @{
            StorageAccountName = $sourceStorageConnection.AccountName
            StorageAccountKey = $sourceStorageConnection.AccountKey
        }
        $sourceStorageContext = New-AzStorageContext @sourceStorageContextParameters

        $sourceContainer = Get-AzStorageContainer -Context $sourceStorageContext | Where-Object { $PSItem.Name -eq $SourceContainerName }

        if ($null -eq $sourceContainer)
        {
            throw ("The source container doesn't exist!")
        }

        $destinationStorageContext = @{}

        if ($SourceConnectionStringName -eq $DestinationConnectionStringName)
        {
            $destinationStorageContext = $sourceStorageContext
        }
        else
        {
            $destinationStorageConnectionParameters = @{
                ResourceGroupName = $ResourceGroupName
                WebAppName = $WebAppName
                ConnectionStringName = $DestinationConnectionStringName
            }
            $destinationStorageConnection = Get-AzureWebAppStorageConnection @destinationStorageConnectionParameters

            $destinationStorageContextParameters = @{
                StorageAccountName = $destinationStorageConnection.AccountName
                StorageAccountKey = $destinationStorageConnection.AccountKey
            }
            $destinationStorageContext = New-AzStorageContext @destinationStorageContextParameters
        }

        $destinationContainer = Get-AzStorageContainer -Context $destinationStorageContext |
            Where-Object { $PSItem.Name -eq $DestinationContainerName }
        $destinationContainerCreated = $false

        if ($null -eq $destinationContainer)
        {
            do
            {
                try
                {
                    $destinationContainerParameters = @{
                        Context = $destinationStorageContext
                        Permission = $sourceContainer.PublicAccess
                        Name = $DestinationContainerName
                        ErrorAction = 'Stop'
                    }
                    $destinationContainer = New-AzStorageContainer @destinationContainerParameters

                    $destinationContainerCreated = $true
                }
                # Catching [Microsoft.WindowsAzure.Storage.StorageException] is not sufficient for some reason...
                catch [System.Net.WebException], [System.Exception]
                {
                    Write-Warning ("Error during creating the container `"$DestinationContainerName`"." +
                        " Retrying in a few seconds...`n" + $PSItem.Exception.Message + "`n")
                    Start-Sleep 5
                }
            }
            while (!$destinationContainerCreated)
        }

        Write-Output ("`n*****`nCopying blobs from `"$SourceContainerName`" to `"$DestinationContainerName`":`n*****")

        foreach ($blob in $sourceContainer | Get-AzStorageBlob)
        {
            if (-not $Force.IsPresent -and -not $destinationContainerCreated)
            {
                $destinationBlobParameters = @{
                    Context = $destinationStorageContext
                    Container = $DestinationContainerName
                    Blob = $blob.Name
                    ErrorAction = 'SilentlyContinue'
                }
                $destinationBlob = Get-AzStorageBlob @destinationBlobParameters

                if ($null -ne $destinationBlob)
                {
                    Write-Output ("Skipped `"$($destinationBlob.Name)`".")

                    continue
                }
            }

            $copyParameters = @{
                Context = $sourceStorageContext
                SrcContainer = $SourceContainerName
                SrcBlob = $blob.Name
                DestContext = $destinationStorageContext
                DestContainer = $DestinationContainerName
                DestBlob = $blob.Name
                Force = $true
            }
            Start-AzStorageBlobCopy @copyParameters | Out-Null

            Write-Output ("Copied `"$($blob.Name)`".")
        }

        Write-Output ("*****`nFinished copying blobs from `"$SourceContainerName`" to `"$DestinationContainerName`"!`n*****`n")
    }
}