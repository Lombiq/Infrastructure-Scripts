<#
.Synopsis
   Returns information of an Azure SQL database based on a connection string stored at a specific Web App.

.DESCRIPTION
   Given an Azure subscription name, a Web App name and a connection string name, the script will retrieve information about a specific Azure SQL database.

.EXAMPLE
   Get-AzureWebAppSqlDatabase -ResourceGroupName "YeahSubscribe" -WebAppName "EverythingIsAnApp" -ConnectionStringName "Nokia"
#>


Import-Module Az.Sql

function Get-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias()]
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
        $databaseConnection = Get-AzureWebAppSqlDatabaseConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $ConnectionStringName
        return Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $databaseConnection.ServerName -DatabaseName $databaseConnection.DatabaseName -ErrorAction Stop
    }
}