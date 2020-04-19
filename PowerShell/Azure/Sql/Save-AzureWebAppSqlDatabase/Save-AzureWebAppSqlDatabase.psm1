<#
.Synopsis
   Exports a database of an Azure Web App to Blob Storage snychronously and downloads it to a specified destination.

.DESCRIPTION
   Exports a database of an Azure Web App to Blob Storage snychronously and downloads it to a specified destination.

.EXAMPLE
   Save-AzureWebAppSqlDatabase -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -DatabaseConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString" -StorageConnectionStringName "Orchard.Azure.Media.StorageConnectionString" -ContainerName "database" -BlobName "export.bacpac" -Destination "C:\backup"
#>


Import-Module Az.Storage

function Save-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias("sawadb")]
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
        [string] $BlobName = $(throw "You need to provide a name for the blob."),

        [Parameter(Mandatory = $true, HelpMessage = "The path on the local machine where the exported database will be downloaded.")]
        [string] $Destination = $(throw "You need to provide a path to download the exported database to.")
    )

    Process
    {
        Invoke-AzureWebAppSqlDatabaseExport -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -DatabaseConnectionStringName $DatabaseConnectionStringName -StorageConnectionStringName $StorageConnectionStringName -ContainerName $ContainerName -BlobName $BlobName

        $storageConnection = Get-AzureWebAppStorageConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $StorageConnectionStringName
        $storageContext = New-AzStorageContext -StorageAccountName $storageConnection.AccountName -StorageAccountKey $storageConnection.AccountKey

        Write-Host ("`n*****`nDownloading exported database...`n*****")

        Get-AzStorageBlobContent -Context $storageContext -Container $ContainerName -Blob $BlobName -Destination $Destination -ErrorAction Stop -Force

        Write-Host ("`n*****`nDownloading finished!`n*****")

        Remove-AzStorageBlob -Context $storageContext -Container $ContainerName -Blob $BlobName -ErrorAction Stop -Force

        Write-Host ("`n*****`nBlob deleted!`n*****")
    }
}