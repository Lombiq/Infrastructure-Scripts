Import-Module Az.Accounts

function Set-AzContextWrapper
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Profile.Models.Core.PSAzureContext])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $SubscriptionId
    )

    Process
    {
        $azContext = Get-AzContext

        if ($azContext.Subscription.Id -ne $SubscriptionId)
        {
            $azContext = Set-AzContext -Subscription $SubscriptionId
        }

        if ($azContext.Subscription.Id -ne $SubscriptionId)
        {
            throw "Could not select the Azure Subscription with the ID `"$SubscriptionId`"!"
        }

        return $azContext
    }
}