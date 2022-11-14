﻿function Start-TCBuild
{
    [CmdletBinding()]
    [Alias("satcb")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The fully qualified URL of the TeamCity server.")]
        [string] $ServerUrl = $(throw "You need to specify the TeamCity server URL."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the user to authenticate with.")]
        [string] $Username = $(throw "You need to specify the username."),

        [Parameter(Mandatory = $true, HelpMessage = "The password of the user.")]
        [SecureString] $Password = $(throw "You need to specify the password."),

        [Parameter(Mandatory = $true, HelpMessage = "The ID of the build configuration to trigger.")]
        [string] $BuildId = $(throw "You need to specify the build ID."),

        [Parameter(HelpMessage = "Number of retries for triggering the build in case of an error. Default value is 3.")]
        [int] $RetryCount = 3
    )
    Process
    {
        $result = @()
        $success = $false
        $retryCounter = 0

        do
        {
            try
            {
                $url = "$ServerUrl/httpAuth/app/rest/buildQueue"
                $authentication = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $Password))
                $body = "<build><buildType id=`"$BuildId`"/></build>"

                Invoke-RestMethod -Uri $url -Method Post -Headers @{ Authorization = $authentication } -ContentType "application/xml" -Body $body

                $success = $true
            }
            catch [System.Exception]
            {
                if ($retryCounter -ge $RetryCount)
                {
                    throw "Could not trigger `"$BuildId`"!"
                }

                $retryCounter++

                Write-Warning "Triggering `"$BuildId`" failed. Retrying..."
            }
        }
        while (!$success)

        Write-Output "Successfully triggered `"$BuildId`"!"
    }
}