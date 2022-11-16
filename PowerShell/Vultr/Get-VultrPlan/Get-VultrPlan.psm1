function Get-VultrPlan
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $ApiKey,

        [Parameter(Mandatory = $false)]
        [Switch] $BareMetal
    )

    process
    {
        $endpoint = "plans"
        if ($BareMetal.IsPresent)
        {
            $endpoint = "plans-metal"
        }

        $response = (Invoke-WebRequest -Uri "https://api.vultr.com/v2/$endpoint" -Headers @{"Authorization" = "Bearer $ApiKey" } -UseBasicParsing)
        $result = ConvertFrom-Json $response

        if ($BareMetal.IsPresent)
        {
            return $result.plans_metal
        }
        else
        {
            return $result.plans
        }
    }
}