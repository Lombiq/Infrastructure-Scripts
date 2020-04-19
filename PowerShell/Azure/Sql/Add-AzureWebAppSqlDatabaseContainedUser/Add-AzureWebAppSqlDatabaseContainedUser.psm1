<#
.Synopsis
   Adds a contained user to a SQL Azure database.

.DESCRIPTION
   Adds a contained user to a SQL Azure database specified by a Subscription name, a Web App name, the database's Connection String name and a Connection String name that provides the user credentials.

.EXAMPLE
   Add-AzureWebAppSqlDatabaseContainedUser -ResourceGroupName "LikeAndSubscribe" -WebAppName "AppsEverywhere" -ConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString.Localhost-master" -UserConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString.Localhost"
#>


function Add-AzureWebAppSqlDatabaseContainedUser
{
    [CmdletBinding()]
    [Alias("aawasdcu")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure subscription on which the Web App is stored. The script throws exception if there is no subscription registered with the given name.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Azure subscription."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the connection string of the database. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $ConnectionStringName = $(throw "You need to provide a connection string name for the database to run the query with."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the connection string that holds the user credentials to add to the database. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $UserConnectionStringName = $(throw "You need to provide a connection string name for the user credentials."),

        [Parameter(HelpMessage = "The role of the user to be added to the database. The default value is `"db_owner`".")]
        [string] $UserRole = "db_owner"
    )

    Process
    {
        if ($ConnectionStringName -eq $UserConnectionStringName)
        {
            throw ("The database and user connection string names can not be the same!")
        }

        $userDatabaseConnection = Get-AzureWebAppSqlDatabaseConnection -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $UserConnectionStringName

        $query = "CREATE USER [$($userDatabaseConnection.UserName)] WITH PASSWORD = '$($userDatabaseConnection.Password)'; ALTER ROLE [$UserRole] ADD MEMBER [$($userDatabaseConnection.UserName)];"

        return Invoke-AzureWebAppSqlQuery -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $ConnectionStringName -Query $query
    }
}