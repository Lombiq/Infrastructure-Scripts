function Get-UTRMonitorDowntimeDuration
{
    [CmdletBinding()]
    [Alias("gutrmdd")]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The UpTimeRobot API key to access monitors. When using an API" +
            " key that is not specific to a monitor, you also need to define the monitor ID as well.")]
        [string] $ApiKey,

        [Parameter(HelpMessage = "The monitor ID.")]
        [string] $MonitorId
    )


    Process
    {
        try
        {
            $response = Get-UTRMonitors -ApiKey $ApiKey -MonitorIds $MonitorId -StatusIds "9"
        }
        catch
        {
            Write-Error "Failed to reach UpTimeRobot API!"

            Write-Error -Exception $PSItem.Exception

            exit 1
        }


        switch ($response.stat)
        {
            "ok"
            {
                break
            }
            "fail"
            {
                Write-Error $response.error

                throw("Failed to retrieve monitor data!")
            }
            Default
            {
                Write-Error $response

                throw("Unknown response status!")
            }
        }


        switch ($response.monitors.Count)
        {
            0
            {
                Write-Output "Monitor is UP!"

                return 0
            }
            1
            {
                $monitor = $response.monitors[0]

                Write-Warning "$($monitor.friendly_name) (monitor ID: $($monitor.id)) is DOWN for $($monitor.logs[0].duration) seconds!"

                return $monitor.logs[0].duration
            }
            Default
            {
                throw("Multiple monitors returned! Please make sure that you use a monitor-specific API key or provide a single monitor ID.")
            }
        }
    }
}
