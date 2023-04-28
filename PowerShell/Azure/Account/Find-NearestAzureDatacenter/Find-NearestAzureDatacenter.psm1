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
        [ValidateSet('Africa', 'Asia Pacific', 'Canada', 'Europe', 'Middle East', 'US')]
        [string] $Region
    )

    process
    {
        # This list is not necessarily complete and depends on the intersection between the regions available in
        # Lombiq's subscriptions and the regions where storage accounts can be created.
        $datacenters = ConvertFrom-Json '[{"Region":"US","Name":"eastus","DisplayName":"East US"},{"Region":"US","Name":"eastus2","DisplayName":"East US 2"},{"Region":"US","Name":"southcentralus","DisplayName":"South Central US"},{"Region":"US","Name":"westus2","DisplayName":"West US 2"},{"Region":"US","Name":"westus3","DisplayName":"West US 3"},{"Region":"Asia Pacific","Name":"australiaeast","DisplayName":"Australia East"},{"Region":"Asia Pacific","Name":"southeastasia","DisplayName":"Southeast Asia"},{"Region":"Europe","Name":"northeurope","DisplayName":"North Europe"},{"Region":"Europe","Name":"swedencentral","DisplayName":"Sweden Central"},{"Region":"Europe","Name":"westeurope","DisplayName":"West Europe"},{"Region":"US","Name":"centralus","DisplayName":"Central US"},{"Region":"Africa","Name":"southafricanorth","DisplayName":"South Africa North"},{"Region":"Asia Pacific","Name":"centralindia","DisplayName":"Central India"},{"Region":"Asia Pacific","Name":"eastasia","DisplayName":"East Asia"},{"Region":"Asia Pacific","Name":"japaneast","DisplayName":"Japan East"},{"Region":"Asia Pacific","Name":"koreacentral","DisplayName":"Korea Central"},{"Region":"Canada","Name":"canadacentral","DisplayName":"Canada Central"},{"Region":"Europe","Name":"francecentral","DisplayName":"France Central"},{"Region":"Europe","Name":"norwayeast","DisplayName":"Norway East"},{"Region":"Europe","Name":"switzerlandnorth","DisplayName":"Switzerland North"},{"Region":"Middle East","Name":"uaenorth","DisplayName":"UAE North"},{"Region":"Middle East","Name":"qatarcentral","DisplayName":"Qatar Central"},{"Region":"US","Name":"northcentralus","DisplayName":"North Central US"},{"Region":"US","Name":"westus","DisplayName":"West US"},{"Region":"US","Name":"westcentralus","DisplayName":"West Central US"},{"Region":"Asia Pacific","Name":"australiasoutheast","DisplayName":"Australia Southeast"},{"Region":"Asia Pacific","Name":"japanwest","DisplayName":"Japan West"},{"Region":"Asia Pacific","Name":"koreasouth","DisplayName":"Korea South"},{"Region":"Asia Pacific","Name":"southindia","DisplayName":"South India"},{"Region":"Asia Pacific","Name":"westindia","DisplayName":"West India"},{"Region":"South America","Name":"brazilsouth","DisplayName":"Brazil South"},{"Region":"Europe","Name":"uksouth","DisplayName":"UK South"},{"Region":"Europe","Name":"ukwest","DisplayName":"UK West"},{"Region":"Asia Pacific","Name":"australiacentral","DisplayName":"Australia Central"},{"Region":"Europe","Name":"germanywestcentral","DisplayName":"Germany West Central"}]'

        if ($Region)
        {
            $datacenters = $datacenters | Where-Object { $PSItem.Region -eq $Region }
        }

        foreach ($datacenter in $datacenters)
        {
            # LAST stands for Lombiq Azure Speed Test.
            $url = "https://last$($datacenter.Name).blob.core.windows.net/speedtest/speedtest.txt"
            $datacenter | Add-Member -MemberType NoteProperty -Name 'Latency' -Value (Measure-Latency($url))
        }

        return ($datacenters | Sort-Object Latency)[0]
    }
}
