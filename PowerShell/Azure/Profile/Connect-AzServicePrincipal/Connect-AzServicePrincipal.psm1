Import-Module Az.Accounts

function Connect-AzServicePrincipal
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Profile.Models.Core.PSAzureProfile])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $TenantId = $(throw "Please provide the ID of the Azure Active Directory!"),

        [Parameter(Mandatory=$true)]
        [string] $ApplicationId = $(throw "Please provide the ID of the Service Principal Application!"),

        [Parameter(Mandatory=$true)]
        [string] $CertificateThumbprint = $(throw "Please provide the thumbprint of the certificate to authenticate with!"),

        [Parameter()]
        [string] $SubscriptionId
    )

    Process
    {
        function AzLogin
        {
            Connect-AzAccount `
                -ServicePrincipal `
                -TenantId $TenantId `
                -ApplicationId $ApplicationId `
                -CertificateThumbprint $CertificateThumbprint
        }



        $azContext = Get-AzContext

        if ($null -eq $azContext)
        {
            AzLogin

            $azContext = Get-AzContext
        }
        elseif ($azContext.Tenant.Id -ne $TenantId)
        {
            $azContext = Set-AzContext -Tenant $TenantId

            if ($azContext.Tenant.Id -ne $TenantId)
            {
                Disconnect-AzAccount

                AzLogin

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