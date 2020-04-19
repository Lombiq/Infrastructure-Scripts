param
(
    [Parameter(Mandatory = $true, HelpMessage = "The full FTP path of the file on the destination, including the protocol and the file itself.")]
    [string] $Path = $(throw "You need to specify the full FTP path of the file on the destination, including the protocol and the file itself."),

    [Parameter(Mandatory = $true, HelpMessage = "FTP username.")]
    [string] $Username = $(throw "You need to specify the FTP username for the connection."),

    [Parameter(Mandatory = $true, HelpMessage = "FTP password.")]
    [string] $Password = $(throw "You need to specify the FTP password for the connection."),

    [Parameter(HelpMessage = "The number of attempts for uploading the file. The default value is 3.")]
    [int] $RetryCount = 3
)

$tryCount = 0
$successful = $false
$ftp = [System.Net.FtpWebRequest]::Create($Path)
$ftp.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
$ftp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)

while ($tryCount -lt $RetryCount -and !$successful)
{
    $tryCount += 1

    try
    {
        $response = [System.Net.FtpWebResponse]$ftp.GetResponse()
        $successful = $true
    }
    catch
    {
        if ($response.StatusCode -eq [System.Net.FtpStatusCode]::FileActionOK)
        {
            Write-Host ("`n*****`nNOTIFICATION: $Path ALREADY DELETED OR NOT AVAILABLE!`n*****`n")
            $response.Close()
            exit 0
        }
    }
}

if ($response -ne $null)
{
    $response.Close()
}

if (!$successful)
{
    Write-Host ("`n*****`nERROR: COULD NOT DELETE $Path!`n*****`n")
    exit 1
}

Write-Host ("`n*****`nNOTIFICATION: SUCCESSFULLY DELETED $Path!`n*****`n")

exit 0