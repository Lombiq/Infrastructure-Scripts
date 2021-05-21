<#
.Synopsis
    Exports a database of an Azure Web App to Blob Storage snychronously.

.DESCRIPTION
    Exports a database of an Azure Web App to Blob Storage snychronously.

.EXAMPLE
    Invoke-AzureWebAppSqlDatabaseExport `
        -ResourceGroupName "CoolStuffHere" `
        -WebAppName "NiceApp" `
        -DatabaseConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString" `
        -StorageConnectionStringName "Orchard.Azure.Media.StorageConnectionString" `
        -ContainerName "database" `
        -BlobName "export.bacpac"
#>


Import-Module Az.Sql

function Invoke-AzureWebAppSqlDatabaseExport
{
    [CmdletBinding()]
    [Alias("iade")]
    [OutputType([Microsoft.Azure.Commands.Sql.ImportExport.Model.AzureSqlDatabaseImportExportBaseModel])]
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
        Write-Host ("`n*****`nDatabase export starting...`n*****")

        $exportRequest = Start-AzureWebAppSqlDatabaseExport `
            -DatabaseResourceGroupName $DatabaseResourceGroupName `
            -DatabaseWebAppName $DatabaseWebAppName `
            -DatabaseSlotName $DatabaseSlotName `
            -DatabaseConnectionStringName $DatabaseConnectionStringName `
            -StorageResourceGroupName $StorageResourceGroupName `
            -StorageWebAppName $StorageWebAppName `
            -StorageSlotName $StorageSlotName `
            -StorageConnectionStringName $StorageConnectionStringName `
            -ContainerName $ContainerName `
            -BlobName $BlobName

        if ($null -eq $exportRequest)
        {
            throw ("Could not start database export!")
        }

        Write-Host ("`n*****`nDatabase export started with the following Status Link:`n$($exportRequest.OperationStatusLink)`n*****")

        $previousStatus = $null

        do
        {
            Start-Sleep 10

            $status = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink -ErrorAction Continue

            if ($status.Status -eq "Failed")
            {
                throw ("Export operation failed: $($status.ErrorMessage)!")
            }
            
            if ($null -eq $previousStatus -or $previousStatus.LastModifiedTime -ne $status.LastModifiedTime)
            {
                $status
            }

            $previousStatus = $status
        }
        while ($status.Status -ne "Succeeded")

        Write-Host ("*****`nDatabase export finished!`n*****`n")

        return $exportRequest
    }
}