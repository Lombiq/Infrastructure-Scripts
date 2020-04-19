<#
.Synopsis
   Starts a one-time copy operation between two Azure SQL databases.

.DESCRIPTION
   Starts a one-time copy operation between two Azure SQL databases (after deleting the destination database if exists) specified by a subscription name, a Web App name and the two Connection String names.

.EXAMPLE
   Copy-AzureWebAppSqlDatabase -ResourceGroupName "YeahSubscribe" -WebAppName "EverythingIsAnApp" -SourceConnectionStringName "CleverDatabase" -DestinationConnectionStringName "NiceDatabase"
#>


Import-Module Az.Sql

function Copy-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias("cawadb")]
    [OutputType([Microsoft.Azure.Commands.Sql.Replication.Model.AzureSqlDatabaseCopyModel])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(HelpMessage = "The name of the connection string of the source database. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $SourceConnectionStringName = $(throw "You need to provide a connection string name for the source database."),

        [Parameter(HelpMessage = "The name of the connection string of the destination database. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $DestinationConnectionStringName = $(throw "You need to provide a connection string name for the destination database."),

        [switch] $Force
    )

    Process
    {
        if ($SourceConnectionStringName -eq $DestinationConnectionStringName)
        {
            throw ("The source and destination connection string names can not be the same!")
        }

        $sourceDatabase = Get-AzureWebAppSqlDatabase -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $SourceConnectionStringName

        if ($sourceDatabase -eq $null)
        {
            throw ("The source database doesn't exist!")
        }

        $destinationDatabaseConnection = Get-AzureWebAppSqlDatabaseConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $DestinationConnectionStringName
        $destinationDatabase = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $destinationDatabaseConnection.ServerName -DatabaseName $destinationDatabaseConnection.DatabaseName -ErrorAction Ignore

        if ($sourceDatabase.ServerName -eq $destinationDatabaseConnection.ServerName -and $sourceDatabase.DatabaseName -eq $destinationDatabaseConnection.DatabaseName)
        {
            throw ("The source and destination databases can not be the same!")
        }

        if ($destinationDatabase -ne $null)
        {
            if ($Force.IsPresent -and (Remove-AzureWebAppSqlDatabase -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $DestinationConnectionStringName) -ne $null)
            {
                Write-Information ("Destination database deleted.")
            }
            else
            {
                throw ("The destination database already exists! Use the Force (switch) to delete it before the copy starts.")
            }
        }

        return (New-AzSqlDatabaseCopy -ResourceGroupName $ResourceGroupName -ServerName $sourceDatabase.ServerName -DatabaseName $sourceDatabase.DatabaseName `
            -CopyServerName $destinationDatabaseConnection.ServerName -CopyDatabaseName $destinationDatabaseConnection.DatabaseName)
    }
}