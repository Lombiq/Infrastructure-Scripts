<#
.Synopsis
   Retrieves a connection string from an Azure Web App.

.DESCRIPTION
   Retrieves a connection string from an Azure Web App identified by the subscription, Web App name (and optional Slot name) and the name of the connection string.

.EXAMPLE
   Get-AzureWebAppWrapper -ResourceGroupName "InsertNameHere" -WebAppName "YummyWebApp" -ConnectionStringName "DatDatabase"

.EXAMPLE
   Get-AzureWebAppWrapper -ResourceGroupName "InsertNameHere" -WebAppName "YummyWebApp" -SlotName "Lucky" -ConnectionStringName "DatDatabase"
#>


Import-Module Az.Websites

function Get-AzureWebAppConnectionString
{
    [CmdletBinding()]
    [Alias("gacs")]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Resource Group.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $WebAppName,

        [Parameter(HelpMessage = "The name of the Web App slot. The default value is `"Production`".")]
        [string] $SlotName = "Production",

        [Parameter(HelpMessage = "The name of a connection string. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $ConnectionStringName = $(throw "You need to provide a connection string name")
    )

    Process
    {
        $webApp = Get-AzureWebAppWrapper -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -SlotName $SlotName

        $connectionString = $webApp.SiteConfig.ConnectionStrings | Where-Object { $PSItem.Name -eq $ConnectionStringName }

        if ([string]::IsNullOrEmpty($connectionString))
        {
            throw ("Connection string with the name `"$ConnectionStringName`" doesn't exist!")
        }

        return $connectionString.ConnectionString
    }
}