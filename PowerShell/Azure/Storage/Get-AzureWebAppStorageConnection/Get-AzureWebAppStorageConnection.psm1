<#
.Synopsis
   Returns the account name and key of an Azure Blob Storage based on a connection string stored at a specific Web App.

.DESCRIPTION
   Given an Azure subscription name, a Web App name and a connection string name, the script will retrieve the account name and key of an Azure Blob Storage.

.EXAMPLE
   Get-AzureWebAppStorageConnection -ResourceGroupName "YeahSubscribe" -WebAppName "EverythingIsAnApp" -ConnectionStringName "Nokia"
#>


function Get-AzureWebAppStorageConnection
{
    [CmdletBinding()]
    [Alias("gasc")]
    [OutputType([Object])]
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
        $connectionString = Get-AzureWebAppConnectionString -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $ConnectionStringName

        $connectionStringElements = $connectionString.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)



        $accountNameElementKey = "AccountName="
        $accountNameElement = $connectionStringElements | Where-Object { $PSItem.StartsWith($accountNameElementKey) }
        if ($accountNameElement -eq $null)
        {
            throw ("The connection string is invalid: Account Name declaration not found!")
        }

        $accountName = $accountNameElement.Substring($accountNameElementKey.Length, $accountNameElement.Length - $accountNameElementKey.Length)
        if ([string]::IsNullOrEmpty($accountName))
        {
            throw ("The connection string is invalid: Account Name not found!")
        }



        $accountKeyElementKey = "AccountKey="
        $accountKeyElement = $connectionStringElements | Where-Object { $PSItem.StartsWith($accountKeyElementKey) }
        if ($accountKeyElement -eq $null)
        {
            throw ("The connection string is invalid: Account Key declaration not found!")
        }

        $accountKey = $accountKeyElement.Substring($accountKeyElementKey.Length, $accountKeyElement.Length - $accountKeyElementKey.Length)
        if ([string]::IsNullOrEmpty($accountKey))
        {
            throw ("The connection string is invalid: Account Key not found!")
        }



        return @{ AccountName = $accountName; AccountKey = $accountKey }
    }
}