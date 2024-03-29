﻿<#
.Synopsis
   Swaps two deployment Slots of an Azure Web App.

.DESCRIPTION
   Swaps two deployment Slots of an Azure Web App and performs transformation on the App Settings and the Connection Strings according to the Lombiq Hosting Suite conventions.

.EXAMPLE
   Switch-AzureWebAppSlots -ResourceGroupName "BestGroup" -WebAppName "CoolApp" -SourceSlotName "Staging" -DestinationSlotName "Production"
#>


Import-Module Az.Websites

function Switch-AzureWebAppSlots
{
    [CmdletBinding()]
    [Alias('swas')]
    [OutputType([int])]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '', Justification = 'This operation always involves multiple Slots.')]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Resource Group the Web App is in.')]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Azure Web App. The script throws exception if' +
            " the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName,

        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Web App slot to swap from.')]
        [string] $SourceSlotName,

        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Web App slot to swap to.')]
        [string] $DestinationSlotName,

        [Parameter(HelpMessage = 'The number of attempts for updating a Web App Slot. The default value is 3.')]
        [int] $RetryCount = 3
    )

    Process
    {
        # Checking and fetching Source and Destination Slots of the Web App.
        if ($SourceSlotName -eq $DestinationSlotName)
        {
            throw ("The Source and the Destination Slots can't be the same.")
        }

        $sourceSlotDataParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SourceSlotName
        }
        $sourceSlotData = Get-AzureWebAppWrapper @sourceSlotDataParameters

        if ($null -eq $sourceSlotData)
        {
            throw ("$SourceSlotName Slot of $WebAppName does not exist!")
        }

        $destinationSlotDataParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $DestinationSlotName
        }
        $destinationSlotData = Get-AzureWebAppWrapper @destinationSlotDataParameters

        if ($null -eq $destinationSlotData)
        {
            throw ("$DestinationSlotName Slot of $WebAppName does not exist!")
        }



        # Processing App Settings for the Destination environment.
        $originalAppSettings = GetAppSettingsFromSlot -Slot $sourceSlotData
        $transformedAppSettings = GetAppSettingsFromSlot -Slot $sourceSlotData
        TransformAppSettings -SlotName $DestinationSlotName -AppSettings $transformedAppSettings

        $appSettingsValidityParameters = @{
            SlotName = $DestinationSlotName
            OriginalAppSettings = $originalAppSettings
            TransformedAppSettings = $transformedAppSettings
        }
        if (-not (VerifyAppSettingsValidity @appSettingsValidityParameters))
        {
            throw "Failed to transform the App Settings for the `"$DestinationSlotName`" Slot!"
        }



        # Processing Connection Strings for the Destination environment.
        $originalConnectionStrings = GetConnectionStringsFromSlot -Slot $sourceSlotData
        $transformedConnectionStrings = GetConnectionStringsFromSlot -Slot $sourceSlotData
        TransformConnectionStrings -SlotName $DestinationSlotName -ConnectionStrings $transformedConnectionStrings

        $connectionStringsValidityParameters = @{
            SlotName = $DestinationSlotName
            OriginalConnectionStrings = $originalConnectionStrings
            TransformedConnectionStrings = $transformedConnectionStrings
        }
        if (-not (VerifyConnectionStringsValidity @connectionStringsValidityParameters))
        {
            throw "Failed to transform the Connection Strings for the `"$DestinationSlotName`" Slot!"
        }



        # Applying the transformed App Settings and Connection Strings to the Source environment with Destination settings.
        $updateSourceSlotDataParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SourceSlotName
            AppSettings = $transformedAppSettings
            ConnectionStrings = $transformedConnectionStrings
            RetryCount = $RetryCount
        }
        $updatedSourceSlotData = UpdateWebAppSlotAppSettingsAndConnectionStrings @updateSourceSlotDataParameters

        # Verifying App Settings vailidity in the Source environment against Destination settings.
        $appSettingsValidityParameters = @{
            SlotName = $DestinationSlotName
            OriginalAppSettings = $originalAppSettings
            TransformedAppSettings = (GetAppSettingsFromSlot -Slot $updatedSourceSlotData)
        }
        $appSettingsValid = VerifyAppSettingsValidity @appSettingsValidityParameters
        if (-not $appSettingsValid)
        {
            Write-Error "Failed to upload the transformed App Settings to the `"$SourceSlotName`" Slot!"
        }

        # Verifying Connection Strings vailidity in the Source environment against Destination settings.
        $connectionStringsValidityParameters = @{
            SlotName = $DestinationSlotName
            OriginalConnectionStrings = $originalConnectionStrings
            TransformedConnectionStrings = (GetConnectionStringsFromSlot -Slot $updatedSourceSlotData)
        }
        $connectionStringsValid = VerifyConnectionStringsValidity @connectionStringsValidityParameters
        if (-not $appSettingsValid)
        {
            Write-Error "Failed to upload the transformed Connection Strings to the `"$SourceSlotName`" Slot!"
        }

        # Stopping the Source environment and the script execution if the App Settings or the Connection Strings are not valid for the Destination environment.
        if (-not $appSettingsValid -or -not $connectionStringsValid)
        {
            $stopWebAppSlotParameters = @{
                ResourceGroupName = $ResourceGroupName
                Name = $WebAppName
                Slot = $SourceSlotName
            }
            Stop-AzWebAppSlot @stopWebAppSlotParameters | Out-Null

            Write-Warning "Attempting to restore the original App Settings and Connection Strings for the `"$SourceSlotName`" Slot of `"$WebAppName`"!"

            $updateWebAppSlotParameters = @{
                ResourceGroupName = $ResourceGroupName
                WebAppName = $WebAppName
                SlotName = $SourceSlotName
                AppSettings = $originalAppSettings
                ConnectionStrings = $originalConnectionStrings
                RetryCount = $RetryCount
            }
            UpdateWebAppSlotAppSettingsAndConnectionStrings @updateWebAppSlotParameters | Out-Null

            throw ("Failed to correctly update the `"$SourceSlotName`" Slot of `"$WebAppName`" for the `"$DestinationSlotName`" environment!")
        }



        # Sending a warm-up request to the Source environment.
        $pingWebAppSlotParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SourceSlotName
            RetryCount = 10
        }
        Test-AzureWebApp @pingWebAppSlotParameters



        # Performing the actual swap.
        try
        {
            $swapWebAppSlotsParameters = @{
                ResourceGroupName = $ResourceGroupName
                Name = $WebAppName
                SourceSlotName = $SourceSlotName
                DestinationSlotName = $DestinationSlotName
                ErrorAction = 'Stop'
            }
            Switch-AzWebAppSlot @swapWebAppSlotsParameters
        }
        catch [Exception]
        {
            # Stopping the Source environment and the script execution if swapping the Slots failed.
            $stopWebAppSlotParameters = @{
                ResourceGroupName = $ResourceGroupName
                Name = $WebAppName
                Slot = $SourceSlotName
            }
            Stop-AzWebAppSlot @stopWebAppSlotParameters | Out-Null

            throw
        }


        # We happy.
        Write-Output ("`n*****`nTHE `"$SourceSlotName`" AND `"$DestinationSlotName`" SLOTS OF `"$WebAppName`" HAVE BEEN SWAPPED!`n*****`n")



        # Sending a warm-up request to the Destination environment.
        $pingWebAppSlotParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $DestinationSlotName
            RetryCount = 10
        }
        Test-AzureWebApp @pingWebAppSlotParameters



        # Processing App Settings for the Source environment.
        $transformedAppSettings = GetAppSettingsFromSlot -Slot $sourceSlotData
        TransformAppSettings -SlotName $SourceSlotName -AppSettings $transformedAppSettings

        $appSettingsValidityParameters = @{
            SlotName = $SourceSlotName
            OriginalAppSettings = $originalAppSettings
            TransformedAppSettings = $transformedAppSettings
        }
        if (-not (VerifyAppSettingsValidity @appSettingsValidityParameters))
        {
            throw "Failed to transform the App Settings for the `"$SourceSlotName`" Slot!"
        }



        # Processing Connection Strings for the Source environment.
        $transformedConnectionStrings = GetConnectionStringsFromSlot -Slot $sourceSlotData
        TransformConnectionStrings -SlotName $SourceSlotName -ConnectionStrings $transformedConnectionStrings

        $connectionStringsValidityParameters = @{
            SlotName = $SourceSlotName
            OriginalConnectionStrings = $originalConnectionStrings
            TransformedConnectionStrings = $transformedConnectionStrings
        }
        if (-not (VerifyConnectionStringsValidity @connectionStringsValidityParameters))
        {
            throw "Failed to transform the Connection Strings for the `"$SourceSlotName`" Slot!"
        }



        # Applying the transformed App Settings and Connection Strings to the Source environment with Source settings.
        $updateSourceSlotDataParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SourceSlotName
            AppSettings = $transformedAppSettings
            ConnectionStrings = $transformedConnectionStrings
            RetryCount = $RetryCount
        }
        $updatedSourceSlotData = UpdateWebAppSlotAppSettingsAndConnectionStrings @updateSourceSlotDataParameters

        # Verifying App Settings vailidity in the Source environment against SourceSlotName settings.
        $appSettingsValidityParameters = @{
            SlotName = $SourceSlotName
            OriginalAppSettings = $originalAppSettings
            TransformedAppSettings = (GetAppSettingsFromSlot -Slot $updatedSourceSlotData)
        }
        $appSettingsValid = VerifyAppSettingsValidity @appSettingsValidityParameters
        if (-not $appSettingsValid)
        {
            Write-Error "Failed to upload the transformed App Settings to the `"$SourceSlotName`" Slot!"
        }

        # Verifying Connection Strings vailidity in the Source environment against SourceSlotName settings.
        $connectionStringsValidityParameters = @{
            SlotName = $SourceSlotName
            OriginalConnectionStrings = $originalConnectionStrings
            TransformedConnectionStrings = (GetConnectionStringsFromSlot -Slot $updatedSourceSlotData)
        }
        $connectionStringsValid = VerifyConnectionStringsValidity @connectionStringsValidityParameters
        if (-not $appSettingsValid)
        {
            Write-Error "Failed to upload the transformed Connection Strings to the `"$SourceSlotName`" Slot!"
        }

        # Stopping the Source environment and the script execution if the App Settings or the Connection Strings are not valid for the Source environment.
        if (-not $appSettingsValid -or -not $connectionStringsValid)
        {
            $stopWebAppSlotParameters = @{
                ResourceGroupName = $ResourceGroupName
                Name = $WebAppName
                Slot = $SourceSlotName
            }
            Stop-AzWebAppSlot @stopWebAppSlotParameters | Out-Null

            Write-Warning "Attempting to restore the original App Settings and Connection Strings for the `"$SourceSlotName`" Slot of `"$WebAppName`"!"

            $updateWebAppSlotParameters = @{
                ResourceGroupName = $ResourceGroupName
                WebAppName = $WebAppName
                SlotName = $SourceSlotName
                AppSettings = $originalAppSettings
                ConnectionStrings = $originalConnectionStrings
                RetryCount = $RetryCount
            }
            UpdateWebAppSlotAppSettingsAndConnectionStrings @updateWebAppSlotParameters | Out-Null

            throw ("Failed to correctly update the `"$SourceSlotName`" Slot of `"$WebAppName`" for the `"$SourceSlotName`" environment!")
        }


        # Sending a warm-up request to the Source environment.
        $pingWebAppSlotParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SourceSlotName
            RetryCount = 10
        }
        Test-AzureWebApp @pingWebAppSlotParameters
    }
}



function GetAppSettingsFromSlot
{
    param
    (
        [Microsoft.Azure.Commands.WebApps.Models.PSSite] $Slot
    )
    process
    {
        $appSettings = @{}

        foreach ($appSetting in $Slot.SiteConfig.AppSettings)
        {
            $appSettings[$appSetting.Name] = $appSetting.Value
        }

        return $appSettings
    }
}

function GetConnectionStringsFromSlot
{
    param
    (
        [Microsoft.Azure.Commands.WebApps.Models.PSSite] $Slot
    )
    process
    {
        $connectionStrings = @{}

        foreach ($connectionString in $Slot.SiteConfig.ConnectionStrings)
        {
            $connectionStrings.Add($connectionString.Name, @{
                    Type = $connectionString.Type.ToString()
                    Value = $connectionString.ConnectionString.ToString()
                })
        }

        return $connectionStrings
    }
}

function GetTransformableSlotSettingNames
{
    param
    (
        [string] $SlotName,
        [System.Collections.Hashtable] $Settings
    )
    process
    {
        $settingNames = @()

        foreach ($settingName in ($Settings.Keys | Where-Object { $PSItem.EndsWith(".$SlotName") }))
        {
            $settingNames += $settingName.SubString(0, $settingName.Length - ".$SlotName".Length)
        }

        return $settingNames
    }
}

function TransformAppSettings
{
    param
    (
        [string] $SlotName,
        [System.Collections.Hashtable] $AppSettings
    )
    process
    {
        foreach ($appSettingName in (GetTransformableSlotSettingNames -SlotName $SlotName -Settings $AppSettings))
        {
            $destinationSlotAppSettingName = "$appSettingName.$SlotName"

            # Cheking if there's a matching Destination App Setting for the current one.
            if (-not $AppSettings.ContainsKey($destinationSlotAppSettingName))
            {
                throw ("`"$SlotName`" App Setting counterpart of `"$appSettingName`" is missing!")
            }

            $AppSettings[$appSettingName] = $AppSettings[$destinationSlotAppSettingName]
        }
    }
}

function TransformConnectionStrings
{
    param
    (
        [string] $SlotName,
        [System.Collections.Hashtable] $ConnectionStrings
    )
    process
    {
        foreach ($connectionStringName in (GetTransformableSlotSettingNames -SlotName $SlotName -Settings $ConnectionStrings))
        {
            $destinationSlotConnectionString = $ConnectionStrings["$connectionStringName.$SlotName"]

            # Cheking if there's a matching Destination Connection String for the current one.
            if ($null -eq $destinationSlotConnectionString)
            {
                throw ("`"$SlotName`" Connection String counterpart of `"$connectionStringName`" is missing!")
            }

            if ($null -eq $ConnectionStrings[$connectionStringName])
            {
                $ConnectionStrings.Add($connectionStringName, @{
                        Type = $destinationSlotConnectionString.Type
                        Value = $destinationSlotConnectionString.ConnectionString
                    })
            }
            else
            {
                $ConnectionStrings[$connectionStringName].Type = $destinationSlotConnectionString.Type
                $ConnectionStrings[$connectionStringName].Value = $destinationSlotConnectionString.Value
            }
        }
    }
}

function UpdateWebAppSlotAppSettingsAndConnectionStrings
{
    param
    (
        [string] $ResourceGroupName,
        [string] $WebAppName,
        [string] $SlotName,
        [System.Collections.Hashtable] $AppSettings,
        [System.Collections.Hashtable] $ConnectionStrings,
        [int] $RetryCount
    )
    process
    {
        $success = $false
        $retryCounter = 0
        $slot = New-Object Microsoft.Azure.Management.WebSites.Models.Site

        do
        {
            try
            {
                $updateWebAppSlotParameters = @{
                    ResourceGroupName = $ResourceGroupName
                    Name = $WebAppName
                    Slot = $SlotName
                    AppSettings = $AppSettings
                    ConnectionStrings = $ConnectionStrings
                }
                $slot = Set-AzWebAppSlot @updateWebAppSlotParameters

                $success = $true
            }
            catch [Exception]
            {
                if ($retryCounter -ge $RetryCount)
                {
                    Write-Error "Could not update the `"$SlotName`" Slot of `"$WebAppName`"!"
                    throw
                }

                $retryCounter++

                Write-Warning "Attempt #$retryCounter to update the `"$SlotName`" Slot of `"$WebAppName`" failed. Retrying..."
            }
        }
        while (!$success)

        return $slot
    }
}

function VerifyAppSettingsValidity
{
    param
    (
        [string] $SlotName,
        [System.Collections.Hashtable] $OriginalAppSettings,
        [System.Collections.Hashtable] $TransformedAppSettings
    )
    process
    {
        $appSettingsValid = $true

        foreach ($appSettingName in (GetTransformableSlotSettingNames -SlotName $SlotName -Settings $OriginalAppSettings))
        {
            $slotAppSettingName = "$appSettingName.$SlotName"

            # Comparing the slot-specific App Setting of the Source and Destination Slots.
            if ($OriginalAppSettings[$slotAppSettingName] -ne $TransformedAppSettings[$slotAppSettingName])
            {
                Write-Error ("The `"$SlotName`" Slot's value for the `"$slotAppSettingName`" App Setting is not uploaded!")

                $appSettingsValid = $false
            }
        }

        foreach ($appSettingName in (GetTransformableSlotSettingNames -SlotName $SlotName -Settings $TransformedAppSettings))
        {
            # Comparing the slot-specific and the applied App Setting of the Destination Slot.
            if ($TransformedAppSettings["$appSettingName.$SlotName"] -ne $TransformedAppSettings[$appSettingName])
            {
                Write-Error ("The `"$SlotName`" Slot's value for the `"$appSettingName`" App Setting is not applied!")

                $appSettingsValid = $false
            }
        }

        if (!$appSettingsValid)
        {
            Write-Error ("`n*****`nERROR: THE `"$SlotName`" SLOT'S APP SETTINGS ARE INVALID!`n*****`n")
        }

        return $appSettingsValid
    }
}

function VerifyConnectionStringsValidity
{
    param
    (
        [string] $SlotName,
        [System.Collections.Hashtable] $OriginalConnectionStrings,
        [System.Collections.Hashtable] $TransformedConnectionStrings
    )
    process
    {
        $connectionStringsValid = $true

        foreach ($connectionStringName in (GetTransformableSlotSettingNames -SlotName $SlotName -Settings $OriginalConnectionStrings))
        {
            $slotConnectionStringName = "$connectionStringName.$SlotName"
            $originalSlotConnectionString = $OriginalConnectionStrings[$slotConnectionStringName]
            $transformedSlotConnectionString = $TransformedConnectionStrings[$slotConnectionStringName]

            # Comparing the slot-specific Connection String of the Source and Destination Slots.
            if ($null -eq $originalSlotConnectionString -or $null -eq $transformedSlotConnectionString -or
                $originalSlotConnectionString.Value -ne $transformedSlotConnectionString.Value)
            {
                Write-Error ("The `"$SlotName`" Slot's value for the `"$slotConnectionStringName`" Connection String is not uploaded!")

                $connectionStringsValid = $false
            }
        }

        foreach ($connectionStringName in (GetTransformableSlotSettingNames -SlotName $SlotName -Settings $TransformedConnectionStrings))
        {
            $transformedSlotConnectionString = $TransformedConnectionStrings["$connectionStringName.$SlotName"]
            $transformedAppliedConnectionString = $TransformedConnectionStrings[$connectionStringName]

            # Comparing the slot-specific and the applied Connection String of the Destination Slot.
            if ($null -eq $transformedSlotConnectionString -or $null -eq $transformedAppliedConnectionString -or
                $transformedSlotConnectionString.Value -ne $transformedAppliedConnectionString.Value)
            {
                Write-Error ("The `"$SlotName`" Slot's value for the `"$connectionStringName`" Connection String is not applied!")

                $connectionStringsValid = $false
            }
        }

        if (!$connectionStringsValid)
        {
            Write-Error ("`n*****`nERROR: THE `"$SlotName`" SLOT'S CONNECTION STRINGS ARE INVALID!`n*****`n")
        }

        return $connectionStringsValid
    }
}
