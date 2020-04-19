<#
.Synopsis
   Removes a contained user from a SQL Azure database.

.DESCRIPTION
   Removes a contained user from a SQL Azure database specified by a Subscription name, a Web App name, the database's Connection String name and a Connection String name that provides the user's name.

.EXAMPLE
   Remove-AzureWebAppSqlDatabaseContainedUser -ResourceGroupName "LikeAndSubscribe" -WebAppName "AppsEverywhere" -ConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString.Localhost-master" -UserConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString"
#>


function Remove-AzureWebAppSqlDatabaseContainedUser
{
    [CmdletBinding()]
    [Alias("rawasdcu")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(HelpMessage = "The name of the connection string of the database. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $ConnectionStringName = $(throw "You need to provide a connection string name for the database to run the query with."),

        [Parameter(HelpMessage = "The name of the connection string that holds the user's name to remove from the database. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $UserConnectionStringName = $(throw "You need to provide a connection string name for the user name.")
    )

    Process
    {
        if ($ConnectionStringName -eq $UserConnectionStringName)
        {
            throw ("The database and user connection string names can not be the same!")
        }

        $userDatabaseConnection = Get-AzureWebAppSqlDatabaseConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $UserConnectionStringName

        $query = "DROP USER IF EXISTS [$($userDatabaseConnection.UserName)];"

        return Invoke-AzureWebAppSqlQuery -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $ConnectionStringName -Query $query
    }
}