<#
.Synopsis
    Starts a maintenance through the Hosting Suite API.

.DESCRIPTION
    Starts a maintenance through the Hosting Suite API and waits for it to finish.

.EXAMPLE
    Start-Maintenance -MaintenanceName "TestMaintenance" -Hostname "mywebsite.com" -Usermame "Fox Mulder" -Password "trustno1"
.EXAMPLE
    Start-Maintenance -MaintenanceName "TestMaintenance" -Hostname "mywebsite.com" -Usermame "Fox Mulder" -Password "trustno1" -BatchSize 10 -RetryCount 3
#>


function Invoke-Maintenance
{
    [CmdletBinding()]
    [Alias("imt")]
    [OutputType([int])]
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
        $startMaintenanceParameters = @{
            Hostname = $Hostname
            MaintenanceName = $MaintenanceName
            APIEndpoint = $APIEndpoint
            Username = $Username
            Password = $Password
            BatchSize = $BatchSize
            RetryCount = $RetryCount
            Protocol = $Protocol
        }
        Start-Maintenance @startMaintenanceParameters

        Write-Output ("`n*****`nStarting maintenance `"$MaintenanceName`" at `"$Hostname`"...`n*****")

        $previousProgress = -1
        $progress = 0

        do
        {
            Start-Sleep -Seconds 10

            $getMaintenanceParameters = @{
                Hostname = $Hostname
                MaintenanceName = $MaintenanceName
                Username = $Username
                Password = $Password
                Protocol = $Protocol
            }
            $progress = (Get-Maintenance @getMaintenanceParameters).ProgressPercent

            if ($progress -ne $previousProgress)
            {
                Write-Output "* $progress%"

                $previousProgress = $progress
            }
        }
        while ($progress -ne 100)

        Write-Output ("*****`nFinished maintenance `"$MaintenanceName`" at `"$Hostname`"!`n*****`n")

        return
    }
}