<#
.Synopsis
   Starts a maintenance through the Hosting Suite API.

.DESCRIPTION
   Starts a maintenance through the Hosting Suite API asynchronously.

.EXAMPLE
   Invoke-Maintenance -MaintenanceName "TestMaintenance" -Hostname "mywebsite.com" -Usermame "Fox Mulder" -Password "trustno1"
.EXAMPLE
   Invoke-Maintenance -MaintenanceName "TestMaintenance" -Hostname "mywebsite.com" -Usermame "Fox Mulder" -Password "trustno1" -BatchSize 10 -RetryCount 3
#>


function Start-Maintenance
{
    [CmdletBinding()]
    [Alias("samt")]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
                   HelpMessage = "The name of the maintenance.",
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [string] $MaintenanceName,

        [Parameter(Mandatory = $true,
                   HelpMessage = "The hostname of the API endpoint to send the request for starting the maintenance.
                                  The URL pattern is https://mywebsite.com/api/Lombiq.Hosting.MultiTenancy/Maintenance?maintenanceName=MyMaintenance, but you only need to define mywebsite.com.")]
        [string] $Hostname = $(throw "You need to specify the API endpoint to send the request for starting the maintenance."),

        [Parameter(HelpMessage = "Optional: The API route on the host for starting a maintenance.")]
        [string] $APIEndpoint = "api/Lombiq.Hosting.MultiTenancy/Maintenance",

        [Parameter(Mandatory = $true,
                   HelpMessage = "The name of the user to authenticate. Make sure that the user is in a role that is permitted to start maintenances.")]
        [string] $Username = $(throw "You need to specify the username."),

        [Parameter(Mandatory = $true,
                   HelpMessage = "The password of the user.")]
        [SecureString] $Password = $(throw "You need to specify the password."),

        [Parameter(HelpMessage = "The number of tenants to run the maintenance process in one go.")]
        [int] $BatchSize = 0,

        [Parameter(HelpMessage = "Number of retries for getting the status of the maintenance in case of an error.")]
        [int] $RetryCount = 0,

        [Parameter(HelpMessage = "The request protocol to use (http or https). Https is the default value.")]
        [string] $Protocol = "https"
    )
    Process
    {
        $result = @()
        $success = $false
        $retryCounter = 0
        $maintenanceDescriptor = @()

        do
        {
            try
            {
                $url = "${Protocol}://$Hostname/$APIEndpoint" + "?maintenanceName=$MaintenanceName"
                $authentication = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $Password))

                if ($BatchSize -lt 1)
                {
                    $maintenanceDescriptor = @{ MaintenanceName = "$MaintenanceName" }
                }
                else
                {
                    $maintenanceDescriptor = @{ MaintenanceName = "$MaintenanceName"; BatchSize = $BatchSize }
                }

                # Invoke-RestMethod doesn't return a status code.
                $result = Invoke-WebRequest -Uri $url -Method Post -ContentType "application/json" -Headers @{ Authorization = $authentication } -Body (ConvertTo-Json($maintenanceDescriptor))

                $success = $true
            }
            catch [System.Exception]
            {
                if ($retryCounter -ge $RetryCount)
                {
                    throw "Could not start the maintenance `"$MaintenanceName`" at `"$Hostname`"!"
                }

                $retryCounter++

                Write-Warning "Starting the maintenance `"$MaintenanceName`" at `"$Hostname`" failed. Retrying..."
            }
        }
        while (!$success)

        if ($result.StatusCode -ne 201)
        {
            throw ("Could not start the maintenance `"$MaintenanceName`" at `"$Hostname`"! Server returned status code " + $result.StatusCode + ".")
        }

        Write-Host "Successfully started the maintenance `"$MaintenanceName`" at `"$Hostname`"!"
    }
}