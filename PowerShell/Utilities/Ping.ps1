param
(
    [Parameter(Mandatory = $true, HelpMessage = "Please specifiy a full URL (including protocol) to ping.")]
    [string] $URL = $(throw "You need to provide a full URL (including protocol) to ping."),

    [Parameter(HelpMessage = "The number of attempts for pinging the specified URL. The default value is 3.")]
    [int] $RetryCount = 3
)

if ($RetryCount -lt 1)
{
    Write-Host ("`n*****`nERROR: RETRYCOUNT MUST BE AT LEAST 1!`n*****`n")
    exit 1
}

$tryCount = 0
$successful = $false
$webClient = New-Object Net.WebClient

while ($tryCount -lt $RetryCount -and !$successful)
{
    $successful = $true
    $tryCount += 1

    try
    {
        $webClient.DownloadData($URL) | Out-Null
    }
    catch
    {
        $successful = $false
        Write-Host ("`n*****`nWARNING: FAILED TO PING $URL!`n*****`n")
    }
}

if (!$successful)
{
    Write-Host ("`n*****`nERROR: THE WEBSITE AT $URL CANNOT BE ACCESSED!`n*****`n")
    exit 1
}

Write-Host ("`n*****`nNOTIFICATION: THE WEBSITE AT $URL IS ACCESSIBLE!`n*****`n")

exit 0