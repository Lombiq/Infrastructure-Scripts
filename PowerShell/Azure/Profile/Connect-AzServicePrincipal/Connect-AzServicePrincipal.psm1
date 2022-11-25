Import-Module Az.Accounts

function Connect-AzServicePrincipal
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Profile.Models.Core.PSAzureProfile])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "Please provide the ID of the Azure Active Directory!")]
        [string] $TenantId,

        [Parameter(Mandatory = $true, HelpMessage = "Please provide the ID of the Service Principal Application!")]
        [string] $ApplicationId,

        [Parameter(Mandatory = $true, HelpMessage = "Please provide the thumbprint of the certificate to authenticate with!")]
        [string] $CertificateThumbprint,

        [Parameter()]
        [string] $SubscriptionId
    )

    Process
    {
        $azureConnectionParameters = @{
            ServicePrincipal      = $true
            TenantId              = $TenantId
            ApplicationId         = $ApplicationId
            CertificateThumbprint = $CertificateThumbprint
        }

        $azContext = Get-AzContext

        if ($null -eq $azContext)
        {
            Connect-AzAccount @azureConnectionParameters

            $azContext = Get-AzContext
        }
        elseif ($azContext.Tenant.Id -ne $TenantId)
        {
            $azContext = Set-AzContext -Tenant $TenantId

            if ($azContext.Tenant.Id -ne $TenantId)
            {
                Disconnect-AzAccount

                Connect-AzAccount @azureConnectionParameters

                $azContext = Get-AzContext

                if ($azContext.Tenant.Id -ne $TenantId)
                {
                    throw "Could not login to the Azure Active Directory with the ID `"$TenantId`"!"
                }
            }
        }

        if (-not [string]::IsNullOrEmpty($SubscriptionId))
        {
            $azContext = Set-AzContextWrapper -SubscriptionId $SubscriptionId
        }

        return $azContext
    }
}
