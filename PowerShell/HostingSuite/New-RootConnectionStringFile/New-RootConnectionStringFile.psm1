<#
.Synopsis
   Sets up a root connection string file at a given path taken from an Azure Web App's Connection Strings.

.DESCRIPTION
   Sets up a root connection string file at a given path taken from an Azure Web App's Connection Strings.

.EXAMPLE
   New-RootConnectionStringFile -Path "C:\AwesomeProject\src\Orchard.Web\App_Data\Sites" -FileName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString" -ResourceGroupName "InsertNameHere" -WebAppName "YummyWebApp" -SlotName "Lucky" -ConnectionStringName "DatDatabase"
#>


function New-RootConnectionStringFile
{
    [CmdletBinding()]
    [Alias("nrcs")]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The path where the root connection string file should be placed.")]
        [string] $Path = $(throw "You need to specify the path where the root connection string file should be placed."),

        [Parameter(Mandatory = $true, HelpMessage = "The extensionless name of the root connection string file to be created.")]
        [string] $FileName = $(throw "You need to specify the extensionless name of the root connection string file to be created."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(HelpMessage = "The name of the Web App slot. The default value is `"Production`".")]
        [string] $SlotName = "Production",

        [Parameter(HelpMessage = "The name of a connection string. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $ConnectionStringName = $(throw "You need to provide a connection string name")
    )

    Process
    {
        $connectionString = Get-AzureWebAppConnectionString -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -ConnectionStringName $ConnectionStringName

        New-Item -ItemType File -Name "$FileName.txt" -Path "$Path" -Force | Out-Null
        Set-Content -Path "$Path\$FileName.txt" -Value $connectionString
    }
}