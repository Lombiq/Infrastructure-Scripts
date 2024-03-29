﻿<#
.Synopsis
    Returns information of an Azure SQL database based on a connection string stored at a specific Web App.

.DESCRIPTION
    Given an Azure subscription name, a Web App name, an optional Web App Slot Name and a connection string name, the
    script will retrieve information about a specific Azure SQL database.

.EXAMPLE
    $databaseParameters = @{
        ResourceGroupName = "YeahSubscribe"
        WebAppName = "EverythingIsAnApp"
        ConnectionStringName = "Nokia"
    }
    Get-AzureWebAppSqlDatabase @databaseParameters

.EXAMPLE
    $databaseParameters = @{
        ResourceGroupName = "YeahSubscribe"
        WebAppName = "EverythingIsAnApp"
        SlotName = "Staging"
        ConnectionStringName = "Nokia"
    }
    Get-AzureWebAppSqlDatabase @databaseParameters
#>

Import-Module Az.Sql

function Get-AzureWebAppSqlDatabase
{
    [CmdletBinding()]
    [Alias()]
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
        $databaseConnectionParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SlotName
            ConnectionStringName = $ConnectionStringName
        }
        $databaseConnection = Get-AzureWebAppSqlDatabaseConnection @databaseConnectionParameters

        $databaseParameters = @{
            ResourceGroupName = $databaseConnection.ResourceGroupName
            ServerName = $databaseConnection.ServerName
            DatabaseName = $databaseConnection.DatabaseName
            ErrorAction = 'Stop'
        }
        return Get-AzSqlDatabase @databaseParameters
    }
}
