function Get-UTRMonitor
{
    [CmdletBinding()]
    [Alias('gutrm')]
    [OutputType([object])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'The UpTimeRobot API key to access monitors.')]
        [string] $ApiKey,

        [Parameter(HelpMessage = 'The hyphen-separated list of monitor IDs.')]
        [string] $MonitorIds,

        [Parameter(HelpMessage = 'The hyphen-separated list of status IDs (0: paused, 1: not checked yet, 2: up, 8: seems down, 9: down).')]
        [string] $StatusIds
    )


    Process
    {
        $headers = @{
            'cache-control' = 'no-cache'
            'content-type' = 'application/x-www-form-urlencoded'
        }

        $body = "api_key=$ApiKey&logs=1"

        if ($MonitorIds -ne $null -and $MonitorIds -ne '')
        {
            $body += "&monitors=$MonitorIds"
        }

        if ($StatusIds -ne $null -and $StatusIds -ne '')
        {
            $body += "&statuses=$StatusIds"
        }

        Invoke-RestMethod -Uri 'https://api.uptimerobot.com/v2/getMonitors' -Method Post -Headers $headers -Body $body
    }
}