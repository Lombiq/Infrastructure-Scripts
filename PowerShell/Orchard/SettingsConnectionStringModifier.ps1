param
(
    [Parameter(Mandatory = $true, HelpMessage = "The full path of the Settings.txt file to be modified.")]
    [string] $Path = $(throw "You need to specify the full path of the Settings.txt file to be modified."),

    [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure subscription on which the staging slot of the website containing the connection string is stored.")]
    [string] $SubscriptionName = $(throw "You need to provide the name of the Azure subscription."),

    [Parameter(Mandatory = $true, HelpMessage = "The name of the production website, whose staging slot contains the connection string.")]
    [string] $LiveSiteName = $(throw "You need to provide the name of the production website."),

    [Parameter(HelpMessage = "The name of the connection string.")]
    [string] $ConnectionStringName = "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString"
)



if (!(Test-Path($Path)))
{
    Write-Host ("`n*****`nERROR: SETTINGS FILE NOT FOUND AT $Path!`n*****`n")
    exit 1
}



Import-Module Azure;

$scriptPath = "$PSScriptRoot\..\Azure\Helpers\CheckAzureSubscriptionAndWebsites.ps1"
if (Test-Path($scriptPath))
{
    & $scriptPath -SubscriptionName "$SubscriptionName" -LiveSiteName "$LiveSiteName"
    if ($LASTEXITCODE -ne 0)
    {
        exit $LASTEXITCODE
    }
}
else
{
    Write-Host ("`n*****`nERROR: SCRIPT FILE NOT FOUND AT $scriptPath!`n*****`n")
    exit 1
}



$scriptPath = "$PSScriptRoot\..\Azure\Helpers\GetAzureWebsiteWrapper.ps1"
if (Test-Path($scriptPath))
{
    & $scriptPath -Name "$LiveSiteName" -Slot "Staging"
    $stagingSiteData = $Global:azureWebSiteData
    if ($LASTEXITCODE -ne 0)
    {
        exit $LASTEXITCODE
    }
}
else
{
    Write-Host ("`n*****`nERROR: SCRIPT FILE NOT FOUND AT $scriptPath!`n*****`n")
    exit 1
}



$connectionStrings = $stagingSiteData.ConnectionStrings
$connectionStringInfo = $connectionStrings | ? {$_.Name.Equals($ConnectionStringName)}

if ($connectionStringInfo -eq $null)
{
    Write-Host ("`n*****`nERROR: CONNECTION STRING WITH THE NAME $ConnectionStringName IS MISSING!`n*****`n")
    exit 1
}



$settingsFileContent = Get-Content $Path
$settingsConnectionStringName = "DataConnectionString"
$settingsConnectionStringEntry = $settingsConnectionStringName + ": " + $connectionStringInfo.ConnectionString

for ($i = 0; $i -le $settingsFileContent.Length; $i++)
{
    if ($settingsFileContent[$i] -ne $null -and $settingsFileContent[$i].StartsWith($settingsConnectionStringName))
    {
        $settingsFileContent[$i] = $settingsConnectionStringEntry
        break
    }
}

if ($settingsFileContent.Length -lt $i)
{
    $settingsFileContent += $settingsConnectionStringEntry

    Write-Host ("`n*****`nWARNING: THE $settingsConnectionStringName ENTRY WAS MISSING FROM THE SETTINGS FILE!`n*****`n")
}

Set-Content -Path $Path -Value $settingsFileContent

Write-Host ("`n*****`nNOTIFICATION: SETTINGS.TXT UPDATED WITH THE CONNECTION STRING $connectionStringName!`n*****`n")

exit 0