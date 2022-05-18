function Get-VultrRegionAvailablePlans
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $ApiKey,
        
        [Parameter(Mandatory = $true)]
        [string] $RegionId
    )
    
    process
    {
        $response = (Invoke-WebRequest -Uri "https://api.vultr.com/v2/regions/$RegionId/availability" -Headers @{"Authorization" = "Bearer $ApiKey" } -UseBasicParsing)

        return (ConvertFrom-Json $response).available_plans
    }
}