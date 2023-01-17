<#
.Synopsis
    Removes an Azure SQL database based on a connection string stored at a specific Web App.

.DESCRIPTION
    Given an Azure subscription name, a Web App name, an optional Web App Slot Name and a connection string name, the
    script will remove a specific Azure SQL database.

.EXAMPLE
    $removeDatabaseParameters = @{
        ResourceGroupName = "YeahSubscribe"
        WebAppName = "EverythingIsAnApp"
        ConnectionStringName = "Nokia"
    }
    Remove-AzureWebAppSqlDatabase @removeDatabaseParameters

.EXAMPLE
    $removeDatabaseParameters = @{
        ResourceGroupName = "YeahSubscribe"
        WebAppName = "EverythingIsAnApp"
        SlotName = "Staging"
        ConnectionStringName = "Nokia"
    }
    Remove-AzureWebAppSqlDatabase @removeDatabaseParameters
#>

Import-Module Az.Sql

function Remove-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias('radb')]
    [OutputType([Microsoft.Azure.Commands.Sql.Database.Model.AzureSqlDatabaseModel])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide the name of the Resource Group.')]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide the name of the Web App.')]
        [string] $WebAppName,

        [Parameter(HelpMessage = 'The name of the Web App slot.')]
        [string] $SlotName,

        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide a connection string name.')]
        [string] $ConnectionStringName
    )

    Process
    {
        # Preventing deleting the Production root database accordint to Orchard 1 conventions.
        if ($ConnectionStringName -eq 'Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString' -or
            $ConnectionStringName.EndsWith('.Production'))
        {
            throw "Deleting the Production database is bad, 'mkay?"
        }

        $databaseParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SlotName
            ConnectionStringName = $ConnectionStringName
        }
        $database = Get-AzureWebAppSqlDatabase @databaseParameters

        if ($null -ne $database)
        {
            Write-Warning "`n*****`nDeleting the database named `"$($database.DatabaseName)`" on the server `"$($database.ServerName)`".`n*****`n"

            $removeDatabaseParameters = @{
                ResourceGroupName = $ResourceGroupName
                ServerName = $database.ServerName
                DatabaseName = $database.DatabaseName
                Force = $true
            }
            return Remove-AzSqlDatabase @removeDatabaseParameters
        }

        return $null
    }
}