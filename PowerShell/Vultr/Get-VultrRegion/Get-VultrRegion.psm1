function Get-VultrRegion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $ApiKey
    )

    process
    {
        $response = (Invoke-WebRequest -Uri "https://api.vultr.com/v2/regions" -Headers @{"Authorization" = "Bearer $ApiKey" } -UseBasicParsing)

        return (ConvertFrom-Json $response).regions
    }
}