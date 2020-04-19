<#
.Synopsis
   Exports a database of an Azure Web App to Blob Storage asnychronously.

.DESCRIPTION
   Exports a database of an Azure Web App to Blob Storage asnychronously.

.EXAMPLE
   Start-AzureWebAppSqlDatabaseExport -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -DatabaseConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString" -StorageConnectionStringName "Orchard.Azure.Media.StorageConnectionString" -ContainerName "database" -BlobName "export.bacpac"
#>


Import-Module Az.Storage
Import-Module Az.Sql

function Start-AzureWebAppSqlDatabaseExport
{
    [CmdletBinding()]
    [Alias("saade")]
    [OutputType([Microsoft.Azure.Commands.Sql.ImportExport.Model.AzureSqlDatabaseImportExportBaseModel])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the database. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $DatabaseConnectionStringName = $(throw "You need to provide a connection string name for the database."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the storage to export the database to. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $StorageConnectionStringName = $(throw "You need to provide a connection string name for the storage."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a container in the storage to export the database to.")]
        [string] $ContainerName = $(throw "You need to provide a name for the container."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the blob in the container to create.")]
        [string] $BlobName = $(throw "You need to provide a name for the blob.")
    )

    Process
    {        
        $storageConnection = Get-AzureWebAppStorageConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $StorageConnectionStringName
        $storageContext = New-AzStorageContext -StorageAccountName $storageConnection.AccountName -StorageAccountKey $storageConnection.AccountKey

        $blob = Get-AzStorageBlob -Context $storageContext -Container $ContainerName -Blob $BlobName -ErrorAction SilentlyContinue
        if ($blob -ne $null)
        {
            $blob | Remove-AzStorageBlob -ErrorAction Stop -Force
        }

        $databaseConnection = Get-AzureWebAppSqlDatabaseConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $DatabaseConnectionStringName
        $databaseConnectionCredentials = ConvertTo-SecureString $databaseConnection.Password -AsPlainText -Force

        return (New-AzSqlDatabaseExport -ResourceGroupName $ResourceGroupName -ServerName $databaseConnection.ServerName -DatabaseName $databaseConnection.DatabaseName `
            -AdministratorLogin $databaseConnection.UserName -AdministratorLoginPassword $databaseConnectionCredentials `
            -StorageKeyType "StorageAccessKey" -StorageKey $storageConnection.AccountKey -StorageUri "https://$($storageConnection.AccountName).blob.core.windows.net/$ContainerName/$BlobName" -ErrorAction Stop)
    }
}