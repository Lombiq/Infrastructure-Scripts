<#
.Synopsis
   Removes an Azure SQL database based on a connection string stored at a specific Web App.

.DESCRIPTION
   Given an Azure subscription name, a Web App name and a connection string name, the script will remove a specific Azure SQL database.

.EXAMPLE
   Remove-AzureWebAppSqlDatabase -ResourceGroupName "YeahSubscribe" -WebAppName "EverythingIsAnApp" -ConnectionStringName "Nokia"
#>


Import-Module Az.Sql

function Remove-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias("radb")]
    [OutputType([Microsoft.Azure.Commands.Sql.Database.Model.AzureSqlDatabaseModel])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(HelpMessage = "The name of a connection string. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $ConnectionStringName = $(throw "You need to provide a connection string name")
    )

    Process
    {
        if ($ConnectionStringName -eq "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString" -or $ConnectionStringName.EndsWith(".Production"))
        {
            throw ("Deleting the Production database is bad, 'mkay?")
        }
        
        $database = Get-AzureWebAppSqlDatabase -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $ConnectionStringName
        
        if ($database -ne $null)
        {
            Write-Host ("`n*****`nDeleting the database named `"$($database.DatabaseName)`" on the server `"$($database.ServerName)`".`n*****`n")

            return Remove-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $database.ServerName -DatabaseName $database.DatabaseName -Force
        }

        return $null
    }
}