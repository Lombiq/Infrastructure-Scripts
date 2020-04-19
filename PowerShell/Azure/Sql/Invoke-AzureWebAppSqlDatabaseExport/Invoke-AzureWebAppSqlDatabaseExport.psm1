<#
.Synopsis
   Exports a database of an Azure Web App to Blob Storage snychronously.

.DESCRIPTION
   Exports a database of an Azure Web App to Blob Storage snychronously.

.EXAMPLE
   Invoke-AzureWebAppSqlDatabaseExport -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -DatabaseConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString" -StorageConnectionStringName "Orchard.Azure.Media.StorageConnectionString" -ContainerName "database" -BlobName "export.bacpac"
#>


Import-Module Az.Sql

function Invoke-AzureWebAppSqlDatabaseExport
{
    [CmdletBinding()]
    [Alias("iade")]
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
        Write-Host ("`n*****`nDatabase export starting...`n*****")

        $exportRequest = Start-AzureWebAppSqlDatabaseExport -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -DatabaseConnectionStringName $DatabaseConnectionStringName `
            -StorageConnectionStringName $StorageConnectionStringName -ContainerName $ContainerName -BlobName $BlobName

        if ($exportRequest -eq $null)
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
            
            if ($previousStatus -eq $null -or $previousStatus.LastModifiedTime -ne $status.LastModifiedTime)
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