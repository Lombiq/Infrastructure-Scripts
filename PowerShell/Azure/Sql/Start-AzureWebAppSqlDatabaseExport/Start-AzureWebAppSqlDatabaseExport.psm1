<#
.Synopsis
    Exports a database of an Azure Web App to Blob Storage asnychronously.

.DESCRIPTION
    Exports a database of an Azure Web App to Blob Storage asnychronously.

.EXAMPLE
    Start-AzureWebAppSqlDatabaseExport @{
        ResourceGroupName            = "CoolStuffHere"
        WebAppName                   = "NiceApp"
        DatabaseConnectionStringName = "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString"
        StorageConnectionStringName  = "Orchard.Azure.Media.StorageConnectionString"
        ContainerName                = "database"
        BlobName                     = "export.bacpac"
    }
#>


Import-Module Az.Storage
Import-Module Az.Sql

function Start-AzureWebAppSqlDatabaseExport
{
    [CmdletBinding()]
    [Alias("saade")]
    [OutputType([Microsoft.Azure.Commands.Sql.ImportExport.Model.AzureSqlDatabaseImportExportBaseModel])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
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
        $storageConnection = Get-AzureWebAppStorageConnection @{
            ResourceGroupName    = $StorageResourceGroupName
            WebAppName           = $StorageWebAppName
            SlotName             = $StorageSlotName
            ConnectionStringName = $StorageConnectionStringName
        }

        $storageContext = New-AzStorageContext @{
            StorageAccountName = $storageConnection.AccountName
            StorageAccountKey  = $storageConnection.AccountKey
        }

        $blob = Get-AzStorageBlob @{
            Context     = $storageContext
            Container   = $ContainerName
            Blob        = $BlobName
            ErrorAction = "SilentlyContinue"
        }

        if ($null -ne $blob)
        {
            $blob | Remove-AzStorageBlob -ErrorAction Stop -Force
        }

        $databaseConnection = Get-AzureWebAppSqlDatabaseConnection @{
            ResourceGroupName    = $DatabaseResourceGroupName
            WebAppName           = $DatabaseWebAppName
            SlotName             = $DatabaseSlotName
            ConnectionStringName = $DatabaseConnectionStringName
        }

        return (New-AzSqlDatabaseExport @{
                ResourceGroupName          = $DatabaseResourceGroupName
                ServerName                 = $databaseConnection.ServerName
                DatabaseName               = $databaseConnection.DatabaseName
                AdministratorLogin         = $databaseConnection.UserName
                AdministratorLoginPassword = (ConvertTo-SecureString $databaseConnection.PasswordAsPlainTextForce)
                StorageKeyType             = "StorageAccessKey"
                StorageKey                 = $storageConnection.AccountKey
                StorageUri                 = "https://$($storageConnection.AccountName).blob.core.windows.net/$ContainerName/$BlobName"
                ErrorAction                = "Stop"
            })
    }
}