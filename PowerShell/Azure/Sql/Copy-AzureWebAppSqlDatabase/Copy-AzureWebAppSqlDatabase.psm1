﻿<#
.Synopsis
    Starts a one-time copy operation between two Azure SQL databases.

.DESCRIPTION
    Starts a one-time copy operation between two Azure SQL databases (after deleting the destination database if exists)
    specified the source and the destination databases' connection string names and the web app slots that store them.

.EXAMPLE
    $copyParameters = @{
        ResourceGroupName = "YeahSubscribe"
        WebAppName = "EverythingIsAnApp"
        SourceConnectionStringName = "CleverDatabase"
        DestinationConnectionStringName = "NiceDatabase"
    }
    Copy-AzureWebAppSqlDatabase @copyParameters
#>

Import-Module Az.Sql

function Copy-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias('cawadb')]
    [OutputType([Microsoft.Azure.Commands.Sql.Replication.Model.AzureSqlDatabaseCopyModel])]
    Param
    (
        [Alias('ResourceGroupName')]
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'You need to provide the name of the Resource Group the Source Web App is in.')]
        [string] $SourceResourceGroupName,

        [Alias('WebAppName')]
        [Parameter(Mandatory = $true, HelpMessage = 'You need to provide the name of the Web App.')]
        [string] $SourceWebAppName,

        [Alias('SlotName')]
        [Parameter(HelpMessage = 'The name of the Source Web App slot.')]
        [string] $SourceSlotName,

        [Alias('ConnectionStringName')]
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'You need to provide a connection string name for the source database.')]
        [string] $SourceConnectionStringName,

        [Parameter(HelpMessage = 'The name of the Destination Resource Group if it differs from the Source.')]
        [string] $DestinationResourceGroupName = $SourceResourceGroupName,

        [Parameter(HelpMessage = 'The name of the Destination Web App if it differs from the Source.')]
        [string] $DestinationWebAppName = $SourceWebAppName,

        [Parameter(HelpMessage = 'The name of the Destination Web App Slot if it differs from the Source.')]
        [string] $DestinationSlotName = $SourceSlotName,

        [Parameter(HelpMessage = 'The name of the Destination Connection String if it differs from the Source.')]
        [string] $DestinationConnectionStringName = $SourceConnectionStringName,

        [switch] $Force
    )

    Process
    {
        $sourceDatabaseParameters = @{
            ResourceGroupName = $SourceResourceGroupName
            WebAppName = $SourceWebAppName
            SlotName = $SourceSlotName
            ConnectionStringName = $SourceConnectionStringName
        }
        $sourceDatabase = Get-AzureWebAppSqlDatabase @sourceDatabaseParameters

        if ($null -eq $sourceDatabase)
        {
            throw ("The source database doesn't exist!")
        }

        $destinationDatabaseConnectionParameters = @{
            ResourceGroupName = $DestinationResourceGroupName
            WebAppName = $DestinationWebAppName
            SlotName = $DestinationSlotName
            ConnectionStringName = $DestinationConnectionStringName
        }
        $destinationDatabaseConnection = Get-AzureWebAppSqlDatabaseConnection @destinationDatabaseConnectionParameters

        $destinationDatabaseParameters = @{
            ResourceGroupName = $destinationDatabaseConnection.ResourceGroupName
            ServerName = $destinationDatabaseConnection.ServerName
            DatabaseName = $destinationDatabaseConnection.DatabaseName
            ErrorAction = 'Ignore'
        }
        $destinationDatabase = Get-AzSqlDatabase @destinationDatabaseParameters

        if ($sourceDatabase.ServerName -eq $destinationDatabaseConnection.ServerName -and
            $sourceDatabase.DatabaseName -eq $destinationDatabaseConnection.DatabaseName)
        {
            throw ('The source and destination databases can not be the same!')
        }

        if ($null -ne $destinationDatabase)
        {
            $deleteDatabaseParameters = @{
                ResourceGroupName = $DestinationResourceGroupName
                WebAppName = $DestinationWebAppName
                SlotName = $DestinationSlotName
                ConnectionStringName = $DestinationConnectionStringName
            }
            if ($Force.IsPresent -and $null -ne (Remove-AzureWebAppSqlDatabase @deleteDatabaseParameters))
            {
                Write-Information ('Destination database deleted.')
            }
            else
            {
                throw ('The destination database already exists! Use the Force (switch) to delete it before the copy starts.')
            }
        }

        try
        {
            $copyParameters = @{
                ResourceGroupName = $sourceDatabase.ResourceGroupName
                ServerName = $sourceDatabase.ServerName
                DatabaseName = $sourceDatabase.DatabaseName
                CopyResourceGroupName = $destinationDatabaseConnection.ResourceGroupName
                CopyServerName = $destinationDatabaseConnection.ServerName
                CopyDatabaseName = $destinationDatabaseConnection.DatabaseName
            }
            return New-AzSqlDatabaseCopy @copyParameters

        }
        catch
        {
            Write-Error ('Could not start copying the database!')

            throw
        }
    }
}
