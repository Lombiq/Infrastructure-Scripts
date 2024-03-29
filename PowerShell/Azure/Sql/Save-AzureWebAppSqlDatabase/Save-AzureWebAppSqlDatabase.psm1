﻿<#
.Synopsis
    Exports a database of an Azure Web App to Blob Storage snychronously and downloads it to a specified destination.

.DESCRIPTION
    Exports a database of an Azure Web App to Blob Storage snychronously and downloads it to a specified destination.

.EXAMPLE
    $saveDatabaseParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        DatabaseConnectionStringName = "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString"
        StorageConnectionStringName = "Orchard.Azure.Media.StorageConnectionString"
        ContainerName = "database"
        BlobName = "export.bacpac"
        Destination = "C:\backup"
    }
    Save-AzureWebAppSqlDatabase @saveDatabaseParameters
#>

Import-Module Az.Storage

function Save-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias('sawadb')]
    Param
    (
        [Alias('ResourceGroupName')]
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide the name of the Resource Group the database's Web App is in.")]
        [string] $DatabaseResourceGroupName,

        [Alias('WebAppName')]
        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide the name of the Web App.')]
        [string] $DatabaseWebAppName,

        [Alias('SlotName')]
        [Parameter(HelpMessage = 'The name of the Web App slot.')]
        [string] $DatabaseSlotName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'You need to provide a connection string name for the database.')]
        [string] $DatabaseConnectionStringName,

        [Parameter(HelpMessage = "The name of the storage connection string's Resource Group if it differs from the database's.")]
        [string] $StorageResourceGroupName = $DatabaseResourceGroupName,

        [Parameter(HelpMessage = "The name of the storage connection string's Web App if it differs from the database's.")]
        [string] $StorageWebAppName = $DatabaseWebAppName,

        [Parameter(HelpMessage = "The name of the storage connection string's Web App Slot if it differs from the database's.")]
        [string] $StorageSlotName = $DatabaseSlotName,

        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide a connection string name for the storage.')]
        [string] $StorageConnectionStringName,

        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide the name of the container in the storage to export the database to.')]
        [string] $ContainerName,

        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide a name for the blob in the container to create.')]
        [string] $BlobName,

        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide a path to download the exported database to.')]
        [string] $Destination
    )

    Process
    {
        $exportDatabaseParameters = @{
            DatabaseResourceGroupName = $DatabaseResourceGroupName
            DatabaseWebAppName = $DatabaseWebAppName
            DatabaseSlotName = $DatabaseSlotName
            DatabaseConnectionStringName = $DatabaseConnectionStringName
            StorageResourceGroupName = $StorageResourceGroupName
            StorageWebAppName = $StorageWebAppName
            StorageSlotName = $StorageSlotName
            StorageConnectionStringName = $StorageConnectionStringName
            ContainerName = $ContainerName
            BlobName = $BlobName
        }
        Invoke-AzureWebAppSqlDatabaseExport @exportDatabaseParameters

        $storageConnectionParameters = @{
            ResourceGroupName = $StorageResourceGroupName
            WebAppName = $StorageWebAppName
            SlotName = $StorageSlotName
            ConnectionStringName = $StorageConnectionStringName
        }
        $storageConnection = Get-AzureWebAppStorageConnection @storageConnectionParameters

        $storageContextParameters = @{
            StorageAccountName = $storageConnection.AccountName
            StorageAccountKey = $storageConnection.AccountKey
        }
        $storageContext = New-AzStorageContext @storageContextParameters

        Write-Output ("`n*****`nDownloading exported database...`n*****")

        $blobContentParameters = @{
            Context = $storageContext
            Container = $ContainerName
            Blob = $BlobName
            Destination = $Destination
            ErrorAction = 'Stop'
            Force = $true
        }
        Get-AzStorageBlobContent @blobContentParameters

        Write-Output ("`n*****`nDownloading finished!`n*****")

        $removeBlobParameters = @{
            Context = $storageContext
            Container = $ContainerName
            Blob = $BlobName
            ErrorAction = 'Stop'
            Force = $true
        }
        Remove-AzStorageBlob @removeBlobParameters

        Write-Output ("`n*****`nBlob deleted!`n*****")
    }
}