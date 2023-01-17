<#
.Synopsis
   Stops a specific Slot of an Azure Web App.

.DESCRIPTION
   Stops a specific Slot of an Azure Web App defined by the name of the subscription, the name of the Web App and the name of the Slot after confirming its existence.

.EXAMPLE
   Stop-AzureWebAppSlot -ResourceGroupName "InsertNameHere" -WebAppName "InsertADifferentNameHere" -SlotName "ThisIsAnotherNameAsWell"
#>


Import-Module Az.Websites

function Stop-AzureWebAppSlot
{
    [CmdletBinding()]
    [Alias('spas')]
    [OutputType([Microsoft.Azure.Commands.WebApps.Models.PSSite])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Resource Group the Web App is in.')]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName,

        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Web App slot.')]
        [string] $SlotName
    )

    Process
    {
        $slot = Get-AzureWebAppWrapper -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -SlotName $SlotName

        if ($null -eq $slot)
        {
            throw ("$SlotName SLOT OF $WebAppName DOES NOT EXIST!")
        }
        else
        {
            try
            {
                $slot = Stop-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $WebAppName -Slot $SlotName -ErrorAction Stop
            }
            catch [Exception]
            {
                throw ("COULD NOT STOP $SlotName SLOT OF $WebAppName!" + $PSItem.Exception.Message)
            }

            Write-Information ("`n*****`n$SlotName SLOT OF $WebAppName STOPPED.`n*****`n") -InformationAction Continue

            return $slot
        }
    }
}
