<#
.Synopsis
   Returns the name and server name of an Azure SQL database based on a connection string stored at a specific Web App.

.DESCRIPTION
   Given an Azure subscription name, a Web App name and a connection string name, the script will retrieve the name and server name of a specific Azure SQL database.

.EXAMPLE
   Get-AzureWebAppSqlDatabaseConnection -ResourceGroupName "YeahSubscribe" -WebAppName "EverythingIsAnApp" -ConnectionStringName "Nokia"
#>


function Get-AzureWebAppSqlDatabaseConnection
{
    [CmdletBinding()]
    [Alias("gasdc")]
    [OutputType([Object])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(HelpMessage = "The name of a connection string. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $ConnectionStringName = $(throw "You need to provide a connection string name.")
    )

    Process
    {
        $connectionString = Get-AzureWebAppConnectionString -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $ConnectionStringName

        $connectionStringElements = $connectionString.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)



        $serverElement = $connectionStringElements | Where-Object { $PSItem.StartsWith("Server=") }
        if ($serverElement -eq $null)
        {
            throw ("The connection string is invalid: Server declaration not found!")
        }

        $serverName = $serverElement.Split(":", [System.StringSplitOptions]::RemoveEmptyEntries)[1].Split(".", [System.StringSplitOptions]::RemoveEmptyEntries).Get(0)
        if ([string]::IsNullOrEmpty($serverName))
        {
            throw ("The connection string is invalid: Server name not found!")
        }
        


        $databaseElement = $connectionStringElements | Where-Object { $PSItem.StartsWith("Database=") -or $PSItem.StartsWith("Initial Catalog=") }
        if ($databaseElement -eq $null)
        {
            throw ("The connection string is invalid: Database / Initial Catalog declaration not found!")
        }

        $databaseName = $databaseElement.Split("=", [System.StringSplitOptions]::RemoveEmptyEntries)[1]
        if ([string]::IsNullOrEmpty($databaseName))
        {
            throw ("The connection string is invalid: Database name not found!")
        }


        
        $userIdElement = $connectionStringElements | Where-Object { $PSItem.StartsWith("User ID=") }
        if ($userIdElement -eq $null)
        {
            throw ("The connection string is invalid: User ID declaration not found!")
        }

        $userId = $userIdElement.Split("=", [System.StringSplitOptions]::RemoveEmptyEntries)[1]
        if ([string]::IsNullOrEmpty($userId))
        {
            throw ("The connection string is invalid: User ID not found!")
        }


        
        $userName = $userId.Split("@", [System.StringSplitOptions]::RemoveEmptyEntries)[0]
        if ([string]::IsNullOrEmpty($userName))
        {
            throw ("The connection string is invalid: User name not found!")
        }



        $passwordElementKey = "Password="
        $passwordElement = $connectionStringElements | Where-Object { $PSItem.StartsWith($passwordElementKey) }
        if ($passwordElement -eq $null)
        {
            throw ("The connection string is invalid: Password declaration not found!")
        }

        $password = $passwordElement.Substring($passwordElementKey.Length, $passwordElement.Length - $passwordElementKey.Length)
        if ([string]::IsNullOrEmpty($password))
        {
            throw ("The connection string is invalid: Password not found!")
        }

        

        return @{ DatabaseName = $databaseName; ServerName = $serverName; UserId = $userId; UserName = $userName; Password = $password }
    }
}