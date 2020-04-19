<#
.Synopsis
   Returns all information of a given Azure Web App.

.DESCRIPTION
   Returns all information of a given Azure Web App defined by its subscription and name (and optionally the name of the slot).

.EXAMPLE
   Get-AzureWebAppWrapper -SubscriptionName "InsertNameHere" -WebAppName "YummyWebApp"

.EXAMPLE
   Get-AzureWebAppWrapper -SubscriptionName "InsertNameHere" -WebAppName "YummyWebApp" -SlotName "Fresh"

.EXAMPLE
   Get-AzureWebAppWrapper -SubscriptionName "InsertNameHere" -WebAppName "YummyWebApp" -RetryCount 7
#>


Import-Module Az.Websites

function Get-AzureWebAppWrapper
{
    [CmdletBinding()]
    [Alias("gaw")]
    [OutputType([Microsoft.Azure.Commands.WebApps.Models.PSSite])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(HelpMessage = "The name of the Web App slot. The default value is `"Production`".")]
        [string] $SlotName = "Production",

        [Parameter(HelpMessage = "The number of attempts for retrieving the data of the website. The default value is 3.")]
        [int] $RetryCount = 3
    )

    Process
    {
        $slot = $null
        $retryCounter = 0

        do
        {
            try
            {
                $slot = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $WebAppName -Slot $SlotName -ErrorAction Stop
            }
            catch
            {
                if ($retryCounter -ge $RetryCount)
                {
                    throw "Could not retrieve the Web App `"$WebAppName`":`n$PSItem"
                }

                $retryCounter++

                Write-Warning "Attempt #$retryCounter to retrieve the Web App `"$WebAppName`" failed. Retrying..."
            }
        }
        while ($slot -eq $null)

        return $slot
    }
}