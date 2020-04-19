Import-Module SQLPS

function Invoke-AzureWebAppSqlQuery
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure subscription on which the Web App is stored. The script throws exception if there is no subscription registered with the given name.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Azure subscription."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $ConnectionStringName = $(throw "You need to provide a connection string name."),

        [Parameter(Mandatory = $true)]
        [string] $Query = $(throw "You need to define a query to run.")
    )

    Process
    {
        $databaseConnection = Get-AzureWebAppSqlDatabaseConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $ConnectionStringName

        return Invoke-Sqlcmd -ServerInstance "$($databaseConnection.ServerName).database.windows.net" -Database $databaseConnection.DatabaseName -Username $databaseConnection.UserName -Password $databaseConnection.Password -Query $Query -EncryptConnection
    }
}