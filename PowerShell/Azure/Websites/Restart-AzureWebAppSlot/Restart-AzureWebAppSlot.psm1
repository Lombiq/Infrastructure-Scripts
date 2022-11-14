<#
.Synopsis
   Restarts a specific Slot of an Azure Web App.

.DESCRIPTION
   Restarts a specific Slot of an Azure Web App defined by the name of the subscription, the name of the Web App and the name of the Slot after confirming its existence.

.EXAMPLE
   Restart-AzureWebAppSlot -ResourceGroupName "InsertNameHere" -WebAppName "InsertADifferentNameHere" -SlotName "ThisIsAnotherNameAsWell"
#>


Import-Module Az.Websites

function Restart-AzureWebAppSlot
{
    [CmdletBinding()]
    [Alias("rtas")]
    [OutputType([Microsoft.Azure.Commands.WebApps.Models.PSSite])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Web App slot.")]
        [string] $SlotName = $(throw "You need to specify the name of the Slot to start.")
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
                $slot = Restart-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $WebAppName -Slot $SlotName -ErrorAction Stop
            }
            catch [Exception]
            {
                throw ("COULD NOT RESTART $SlotName SLOT OF $WebAppName!" + $_.Exception.Message)
            }

            Write-Host ("`n*****`n$SlotName SLOT OF $WebAppName RESTARTED.`n*****`n")

            return $slot
        }
    }
}