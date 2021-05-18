<#
.Synopsis
    Adds a contained user to a SQL Azure database with the optionally specified role.

.DESCRIPTION
    Adds a contained user to a SQL Azure database specified by a Subscription name, a Web App name, the database's
    Connection String name and a Connection String name that provides the user credentials.

.EXAMPLE
    Add-AzureWebAppSqlDatabaseContainedUser `
        -ResourceGroupName "LikeAndSubscribe" `
        -WebAppName "AppsEverywhere" `
        -ConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString.Localhost-master" `
        -UserConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString.Localhost"
#>


function Add-AzureWebAppSqlDatabaseContainedUser
{
    [CmdletBinding()]
    [Alias("aawasdcu")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Resource Group.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $WebAppName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a connection string name for the database to run the query with.")]
        [string] $ConnectionStringName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a connection string name for the user credentials.")]
        [string] $UserConnectionStringName,

        [Parameter(HelpMessage = "The role of the user to be added to the database. The default value is `"db_owner`".")]
        [string] $UserRole = "db_owner"
    )

    Process
    {
        if ($ConnectionStringName -eq $UserConnectionStringName)
        {
            throw ("The database and user connection string names can not be the same!")
        }

        $userDatabaseConnection = Get-AzureWebAppSqlDatabaseConnection `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $WebAppName `
            -ConnectionStringName $UserConnectionStringName

        $query = "CREATE USER [$($userDatabaseConnection.UserName)] WITH PASSWORD = '$($userDatabaseConnection.Password)';" +
            "ALTER ROLE [$UserRole] ADD MEMBER [$($userDatabaseConnection.UserName)];"

        return Invoke-AzureWebAppSqlQuery `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $WebAppName `
            -ConnectionStringName $ConnectionStringName `
            -Query $query
    }
}