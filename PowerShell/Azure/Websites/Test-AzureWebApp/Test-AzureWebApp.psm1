<#
.Synopsis
    Pings an Azure Web App through its default hostname.

.DESCRIPTION
    Pings an Azure Web App defined by its subscription and name (and optionally the name of the slot) through its default hostname.

.EXAMPLE
    Test-AzureWebApp -SubscriptionName "InsertNameHere" -WebAppName "YummyWebApp"

.EXAMPLE
    Test-AzureWebApp -SubscriptionName "InsertNameHere" -WebAppName "YummyWebApp" -SlotName "Fresh"
#>


function Test-AzureWebApp
{
    [CmdletBinding()]
    [Alias("taw")]
    [OutputType([object])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName,

        [Parameter(HelpMessage = "The name of the Web App slot. The default value is `"Production`".")]
        [string] $SlotName = "Production",

        [Parameter(HelpMessage = "The request protocol to use (http or https). Https is the default value.")]
        [string] $Protocol = "https",

        [Parameter(HelpMessage = "Request timeout in seconds. The default value is 100.")]
        [int] $Timeout = 100,

        [Parameter(HelpMessage = "The number of seconds to wait between ping attempts. The default value is 15.")]
        [int] $Interval = 15,

        [Parameter(HelpMessage = "The number of attempts for pinging the specified URL. The default value is 3.")]
        [int] $RetryCount = 3
    )

    Process
    {
        $webApp = Get-AzureWebAppWrapper -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -Slot $SlotName

        # Enforcing the result to be an array so it can be indexed even if there's only one matching hostname.
        $url = "${Protocol}://" + ([array]($webApp.EnabledHostNames | Where-Object { $PSItem.EndsWith(".azurewebsites.net") }))[0]

        Write-Output ("Testing the `"$SlotName`" Slot of the Web App `"$WebAppName`" through the URL `"$url`".")

        Test-Url $url -Timeout $Timeout -Interval $Interval -RetryCount $RetryCount
    }
}
