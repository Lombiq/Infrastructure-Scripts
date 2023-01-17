function Get-VultrOperatingSystem
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $ApiKey
    )

    process
    {
        $response = (Invoke-WebRequest -Uri 'https://api.vultr.com/v2/os' -Headers @{'Authorization' = "Bearer $ApiKey" } -UseBasicParsing)

        return (ConvertFrom-Json $response).os
    }
}