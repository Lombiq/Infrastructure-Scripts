<#
.Synopsis
    Exports a database of an Azure Web App to Blob Storage asnychronously.

.DESCRIPTION
    Exports a database of an Azure Web App to Blob Storage asnychronously.

.EXAMPLE
    $exportDatabaseParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        DatabaseConnectionStringName = "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString"
        StorageConnectionStringName = "Orchard.Azure.Media.StorageConnectionString"
        ContainerName = "database"
        BlobName = "export.bacpac"
    }
    Start-AzureWebAppSqlDatabaseExport @exportDatabaseParameters
#>

Import-Module Az.Storage
Import-Module Az.Sql

function Start-AzureWebAppSqlDatabaseExport
{
    [CmdletBinding()]
    [Alias("saade")]
    [OutputType([Microsoft.Azure.Commands.Sql.ImportExport.Model.AzureSqlDatabaseImportExportBaseModel])]
    [Diagnostics.CodeAnalysis.SuppressMessage(
        "PSAvoidUsingConvertToSecureStringWithPlainText",
        "",
        Justification = "Password is fetched from Azure in plain text format already.")]
    Param
    (
        [Alias("ResourceGroupName")]
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide the name of the Resource Group the database's Web App is in.")]
        [string] $DatabaseResourceGroupName,

        [Alias("WebAppName")]
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $DatabaseWebAppName,

        [Parameter(HelpMessage = "The name of the Web App slot.")]
        [string] $DatabaseSlotName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide a connection string name for the database.")]
        [string] $DatabaseConnectionStringName,

        [Parameter(HelpMessage = "The name of the storage connection string's Resource Group if it differs from the database's.")]
        [string] $StorageResourceGroupName = $DatabaseResourceGroupName,

        [Parameter(HelpMessage = "The name of the storage connection string's Web App if it differs from the database's.")]
        [string] $StorageWebAppName = $DatabaseWebAppName,

        [Parameter(HelpMessage = "The name of the storage connection string's Web App Slot if it differs from the database's.")]
        [string] $StorageSlotName = $DatabaseSlotName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a connection string name for the storage.")]
        [string] $StorageConnectionStringName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the container in the storage to export the database to.")]
        [string] $ContainerName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a name for the blob in the container to create.")]
        [string] $BlobName
    )

    Process
    {
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

        $databaseBlobParameters = @{
            Context = $storageContext
            Container = $ContainerName
            Blob = $BlobName
            ErrorAction = "SilentlyContinue"
        }
        $blob = Get-AzStorageBlob @databaseBlobParameters

        if ($null -ne $blob)
        {
            $blob | Remove-AzStorageBlob -ErrorAction Stop -Force
        }

        $databaseConnectionParameters = @{
            ResourceGroupName = $DatabaseResourceGroupName
            WebAppName = $DatabaseWebAppName
            SlotName = $DatabaseSlotName
            ConnectionStringName = $DatabaseConnectionStringName
        }
        $databaseConnection = Get-AzureWebAppSqlDatabaseConnection @databaseConnectionParameters

        $exportParameters = @{
            ResourceGroupName = $DatabaseResourceGroupName
            ServerName = $databaseConnection.ServerName
            DatabaseName = $databaseConnection.DatabaseName
            AdministratorLogin = $databaseConnection.UserName
            AdministratorLoginPassword = (ConvertTo-SecureString $databaseConnection -AsPlainText -Force)
            StorageKeyType = "StorageAccessKey"
            StorageKey = $storageConnection.AccountKey
            StorageUri = "https://$($storageConnection.AccountName).blob.core.windows.net/$ContainerName/$BlobName"
            ErrorAction = "Stop"
        }
        return (New-AzSqlDatabaseExport @exportParameters)
    }
}