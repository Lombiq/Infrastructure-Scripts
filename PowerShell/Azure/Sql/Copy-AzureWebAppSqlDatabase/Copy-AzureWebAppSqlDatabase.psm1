<#
.Synopsis
    Starts a one-time copy operation between two Azure SQL databases.

.DESCRIPTION
    Starts a one-time copy operation between two Azure SQL databases (after deleting the destination database if exists)
    specified by a subscription name, a Web App name and the two Connection String names.

.EXAMPLE
    Copy-AzureWebAppSqlDatabase `
        -ResourceGroupName "YeahSubscribe" `
        -WebAppName "EverythingIsAnApp" `
        -SourceConnectionStringName "CleverDatabase" `
        -DestinationConnectionStringName "NiceDatabase"
#>


Import-Module Az.Sql

function Copy-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias("cawadb")]
    [OutputType([Microsoft.Azure.Commands.Sql.Replication.Model.AzureSqlDatabaseCopyModel])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Resource Group.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $WebAppName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a connection string name for the source database.")]
        [string] $SourceConnectionStringName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a connection string name for the destination database.")]
        [string] $DestinationConnectionStringName,

        [switch] $Force
    )

    Process
    {
        if ($SourceConnectionStringName -eq $DestinationConnectionStringName)
        {
            throw ("The source and destination connection string names can not be the same!")
        }

        $sourceDatabase = Get-AzureWebAppSqlDatabase `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $WebAppName `
            -ConnectionStringName $SourceConnectionStringName

        if ($null -eq $sourceDatabase)
        {
            throw ("The source database doesn't exist!")
        }

        $destinationDatabaseConnection = Get-AzureWebAppSqlDatabaseConnection `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $WebAppName `
            -ConnectionStringName $DestinationConnectionStringName
        
        $destinationDatabase = Get-AzSqlDatabase `
            -ResourceGroupName $ResourceGroupName `
            -ServerName $destinationDatabaseConnection.ServerName `
            -DatabaseName $destinationDatabaseConnection.DatabaseName `
            -ErrorAction Ignore

        if ($sourceDatabase.ServerName -eq $destinationDatabaseConnection.ServerName `
                -and $sourceDatabase.DatabaseName -eq $destinationDatabaseConnection.DatabaseName)
        {
            throw ("The source and destination databases can not be the same!")
        }

        if ($null -ne $destinationDatabase)
        {
            if ($Force.IsPresent `
                    -and $null -ne (Remove-AzureWebAppSqlDatabase `
                        -ResourceGroupName $ResourceGroupName `
                        -WebAppName $WebAppName `
                        -ConnectionStringName $DestinationConnectionStringName))
            {
                Write-Information ("Destination database deleted.")
            }
            else
            {
                throw ("The destination database already exists! Use the Force (switch) to delete it before the copy starts.")
            }
        }

        return New-AzSqlDatabaseCopy `
            -ResourceGroupName $ResourceGroupName `
            -ServerName $sourceDatabase.ServerName `
            -DatabaseName $sourceDatabase.DatabaseName `
            -CopyServerName $destinationDatabaseConnection.ServerName `
            -CopyDatabaseName $destinationDatabaseConnection.DatabaseName
    }
}