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
        [string] $GeographyGroup
    )

    process
    {
        $datacentersJson = '[{"DisplayName":"East US","SpeedTestUrl":"https://speedtesteus.blob.core.windows.net/cb.json","Name":"eastus","GeographyGroup":"US"},{"DisplayName":"East US 2","SpeedTestUrl":"https://speedtesteus2.blob.core.windows.net/cb.json","Name":"eastus2","GeographyGroup":"US"},{"DisplayName":"South Central US","SpeedTestUrl":"https://speedtestscus.blob.core.windows.net/cb.json","Name":"southcentralus","GeographyGroup":"US"},{"DisplayName":"West US 2","SpeedTestUrl":"https://speedtestwestus2.blob.core.windows.net/cb.json","Name":"westus2","GeographyGroup":"US"},{"DisplayName":"West US 3","SpeedTestUrl":"https://azurespeedtestwestus3.z1.web.core.windows.net/","Name":"westus3","GeographyGroup":"US"},{"DisplayName":"Australia East","SpeedTestUrl":"https://speedtestoze.blob.core.windows.net/cb.json","Name":"australiaeast","GeographyGroup":"Asia Pacific"},{"DisplayName":"Southeast Asia","SpeedTestUrl":"https://speedtestsea.blob.core.windows.net/cb.json","Name":"southeastasia","GeographyGroup":"Asia Pacific"},{"DisplayName":"North Europe","SpeedTestUrl":"https://speedtestne.blob.core.windows.net/cb.json","Name":"northeurope","GeographyGroup":"Europe"},{"DisplayName":"Sweden Central","SpeedTestUrl":"https://speedtestesc.blob.core.windows.net/cb.json","Name":"swedencentral","GeographyGroup":"Europe"},{"DisplayName":"West Europe","SpeedTestUrl":"https://speedtestwe.blob.core.windows.net/cb.json","Name":"westeurope","GeographyGroup":"Europe"},{"DisplayName":"Central US","SpeedTestUrl":"https://speedtestcus.blob.core.windows.net/cb.json","Name":"centralus","GeographyGroup":"US"},{"DisplayName":"South Africa North","SpeedTestUrl":"https://speedtestsan.blob.core.windows.net/cb.json","Name":"southafricanorth","GeographyGroup":"Africa"},{"DisplayName":"Central India","SpeedTestUrl":"https://speedtestcentralindia.blob.core.windows.net/cb.json","Name":"centralindia","GeographyGroup":"Asia Pacific"},{"DisplayName":"East Asia","SpeedTestUrl":"https://speedtestea.blob.core.windows.net/cb.json","Name":"eastasia","GeographyGroup":"Asia Pacific"},{"DisplayName":"Japan East","SpeedTestUrl":"https://speedtestjpe.blob.core.windows.net/cb.json","Name":"japaneast","GeographyGroup":"Asia Pacific"},{"DisplayName":"Korea Central","SpeedTestUrl":"https://speedtestkoreacentral.blob.core.windows.net/cb.json","Name":"koreacentral","GeographyGroup":"Asia Pacific"},{"DisplayName":"Canada Central","SpeedTestUrl":"https://speedtestcac.blob.core.windows.net/cb.json","Name":"canadacentral","GeographyGroup":"Canada"},{"DisplayName":"France Central","SpeedTestUrl":"https://speedtestfrc.blob.core.windows.net/cb.json","Name":"francecentral","GeographyGroup":"Europe"},{"DisplayName":"Norway East","SpeedTestUrl":"https://azspeednoeast.blob.core.windows.net/cb.json","Name":"norwayeast","GeographyGroup":"Europe"},{"DisplayName":"Poland Central","SpeedTestUrl":"https://speedtestplc.blob.core.windows.net/cb.json","Name":"polandcentral","GeographyGroup":"Europe"},{"DisplayName":"Switzerland North","SpeedTestUrl":"https://speedtestchn.blob.core.windows.net/cb.json","Name":"switzerlandnorth","GeographyGroup":"Europe"},{"DisplayName":"UAE North","SpeedTestUrl":"https://speedtestuaen.blob.core.windows.net/cb.json","Name":"uaenorth","GeographyGroup":"Middle East"},{"DisplayName":"Qatar Central","SpeedTestUrl":"https://speedtestqc.z1.web.core.windows.net/","Name":"qatarcentral","GeographyGroup":"Middle East"},{"DisplayName":"Brazil","SpeedTestUrl":"https://speedtestnea.blob.core.windows.net/cb.json","Name":"brazil","GeographyGroup":null},{"DisplayName":"North Central US","SpeedTestUrl":"https://speedtestnsus.blob.core.windows.net/cb.json","Name":"northcentralus","GeographyGroup":"US"},{"DisplayName":"West US","SpeedTestUrl":"https://speedtestwus.blob.core.windows.net/cb.json","Name":"westus","GeographyGroup":"US"},{"DisplayName":"West Central US","SpeedTestUrl":"https://speedtestwestcentralus.blob.core.windows.net/cb.json","Name":"westcentralus","GeographyGroup":"US"},{"DisplayName":"Australia Southeast","SpeedTestUrl":"https://speedtestozse.blob.core.windows.net/cb.json","Name":"australiasoutheast","GeographyGroup":"Asia Pacific"},{"DisplayName":"Japan West","SpeedTestUrl":"https://speedtestjpw.blob.core.windows.net/cb.json","Name":"japanwest","GeographyGroup":"Asia Pacific"},{"DisplayName":"Korea South","SpeedTestUrl":"https://speedtestkoreasouth.blob.core.windows.net/cb.json","Name":"koreasouth","GeographyGroup":"Asia Pacific"},{"DisplayName":"South India","SpeedTestUrl":"https://speedtesteastindia.blob.core.windows.net/cb.json","Name":"southindia","GeographyGroup":"Asia Pacific"},{"DisplayName":"West India","SpeedTestUrl":"https://speedtestwestindia.blob.core.windows.net/cb.json","Name":"westindia","GeographyGroup":"Asia Pacific"},{"DisplayName":"Canada East","SpeedTestUrl":"https://speedtestcae.blob.core.windows.net/cb.json","Name":"canadaeast","GeographyGroup":"Canada"},{"DisplayName":"Germany North","SpeedTestUrl":"https://speedtestden.blob.core.windows.net/cb.json","Name":"germanynorth","GeographyGroup":"Europe"},{"DisplayName":"Switzerland West","SpeedTestUrl":"https://speedtestchw.blob.core.windows.net/cb.json","Name":"switzerlandwest","GeographyGroup":"Europe"}]'

        $datacenters = $datacentersJson | ConvertFrom-Json

        if ($GeographyGroup)
        {
            $datacenters = $datacenters | Where-Object { $PSItem.GeographyGroup -eq $GeographyGroup }
        }

        foreach ($datacenter in $datacenters)
        {
            $datacenter | Add-Member -MemberType NoteProperty -Name 'Latency' -Value (Measure-Latency $datacenter.SpeedTestUrl)
        }

        return ($datacenters | Sort-Object Latency)[0]
    }
}
