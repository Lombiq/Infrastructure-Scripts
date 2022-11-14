<#
.Synopsis
    Gets the status of a maintenance through the Hosting Suite API.

.DESCRIPTION
    Gets the status of a maintenance through the Hosting Suite API using the name of the maintenance.

.EXAMPLE
    Get-Maintenance -MaintenanceName "TestMaintenance" -Hostname "mywebsite.com" -Usermame "Fox Mulder" -Password "trustno1"
#>


function Get-Maintenance
{
    [CmdletBinding()]
    [Alias("gmt")]
    [OutputType([object])]
    Param
    (
        [Parameter(Mandatory = $true,
            HelpMessage = "The name of the maintenance.",
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string] $MaintenanceName,

        [Parameter(Mandatory = $true,
            HelpMessage = "The hostname of the API endpoint that returns the maintenance status. The URL pattern is" +
            " https://mywebsite.com/api/Lombiq.Hosting.MultiTenancy/Maintenance?maintenanceName=MyMaintenance," +
            " but you only need to define mywebsite.com.")]
        [string] $Hostname,

        [Parameter(HelpMessage = "Optional: The API route on the host that returns the maintenance status.")]
        [string] $APIEndpoint = "api/Lombiq.Hosting.MultiTenancy/Maintenance",

        [Parameter(Mandatory = $true,
            HelpMessage = "The name of the user to authenticate. Make sure that the user is in a role that is permitted to access maintenances.")]
        [string] $Username = $(throw "You need to specify the username."),

        [Parameter(Mandatory = $true,
            HelpMessage = "The password of the user.")]
        [SecureString] $Password = $(throw "You need to specify the password."),

        [Parameter(HelpMessage = "Number of retries for getting the status of the maintenance in case of an error.")]
        [int] $RetryCount = 0,

        [Parameter(HelpMessage = "The request protocol to use (http or https). Https is the default value.")]
        [string] $Protocol = "https"
    )
    Process
    {
        $result = @()
        $success = $false
        $retryCounter = -1

        do
        {
            try
            {
                $url = "${Protocol}://$Hostname/$APIEndpoint" + "?maintenanceName=$MaintenanceName"
                $authentication = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $Password))

                $result = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -Headers @{ Authorization = $authentication }

                $success = $true
            }
            catch [System.Exception]
            {
                $retryCounter++

                if ($retryCounter -ge $RetryCount)
                {
                    throw "Could not request the status of the maintenance `"$MaintenanceName`" at `"$Hostname`"!"
                }

                Write-Warning "Requesting the status of the maintenance `"$MaintenanceName`" at `"$Hostname`" failed. Retrying..."
            }
        }
        while (!$success)

        if ($result.StatusCode -eq 200)
        {
            return ConvertFrom-Json($result.Content)
        }
        else
        {
            throw ("Could not retrieve status for the maintenance `"$MaintenanceName`" at `"$Hostname`"! Server returned status code " + $result.StatusCode + ".")
        }
    }
}

