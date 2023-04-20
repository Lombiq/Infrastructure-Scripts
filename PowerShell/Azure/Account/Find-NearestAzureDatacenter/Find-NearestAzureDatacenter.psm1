# Measure latency 10 times, ignore the smallest and largest 2 measurements and average the rest.
function Measure-Latency($Url)
{
    $measurements = @()

    for ($i = 0; $i -lt 10; $i++)
    {
        try
        {
            $measurements += (Measure-Command { Invoke-WebRequest $Url -TimeoutSec 1 }).Milliseconds
        }
        catch
        {
            $measurements += 1000
        }
    }

    return (($measurements | Sort-Object)[2..7] | Measure-Object -Average).Average
}

function Find-NearestAzureDatacenter
{
    [CmdletBinding()]
    param
    (
        [string] $GeographyGroup
    )

    process
    {
        $azDatacenters = az account list-locations | ConvertFrom-Json -Depth 9
        $speedTestDatacenters = Get-Content -Raw "$PSScriptRoot/azure-datacenter-speedtest-urls.json" | ConvertFrom-Json

        if ($GeographyGroup)
        {
            $azDatacenters = $azDatacenters | Where-Object { $PSItem.metadata.geographyGroup -eq $GeographyGroup }
        }

        foreach ($azDatacenter in $azDatacenters)
        {
            $speedTestDatacenter = $speedTestDatacenters | Where-Object { $PSItem.name -eq $azDatacenter.displayName }

            if ($speedTestDatacenter)
            {
                $url = "https://$($speedTestDatacenter.domain).blob.core.windows.net/cb.json"
                if ($speedTestDatacenter.url)
                {
                    $url = $speedTestDatacenter.url
                }

                $azDatacenter | Add-Member -MemberType NoteProperty -Name 'speedTestUrl' -Value $url
            }
        }

        $azDatacenters = $azDatacenters | Where-Object { $PSItem.speedTestUrl }

        foreach ($azDatacenter in $azDatacenters)
        {
            $azDatacenter | Add-Member -MemberType NoteProperty -Name 'latency' -Value (Measure-Latency $azDatacenter.speedTestUrl)
        }

        return ($azDatacenters | Sort-Object latency)[0]
    }
}
