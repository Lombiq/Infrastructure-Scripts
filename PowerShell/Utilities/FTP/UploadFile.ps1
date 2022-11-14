param
(
    [Parameter(Mandatory = $true, HelpMessage = "The full path of the file to upload.")]
    [string] $LocalPath = $(throw "You need to specify the full path of the file to be uploaded"),

    [Parameter(Mandatory = $true, HelpMessage = "The full FTP path of the file on the destination, including the protocol and the file itself.")]
    [string] $RemotePath = $(throw "You need to specify the full FTP path of the file on the destination, including the protocol and the file itself."),

    [Parameter(Mandatory = $true, HelpMessage = "FTP username.")]
    [string] $Username = $(throw "You need to specify the FTP username for the connection."),

    [Parameter(Mandatory = $true, HelpMessage = "FTP password.")]
    [SecureString] $Password = $(throw "You need to specify the FTP password for the connection."),

    [Parameter(HelpMessage = "The number of attempts for uploading the file. The default value is 3.")]
    [int] $RetryCount = 3
)

$tryCount = 0
$successful = $false
$webclient = New-Object System.Net.WebClient
$webclient.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
$remoteUri = New-Object System.Uri($RemotePath)

while ($tryCount -lt $RetryCount -and !$successful)
{
    $tryCount += 1

    try
    {
        $webclient.UploadFile($remoteUri, $LocalPath)
        $successful = $true
    }
    catch {}
}

if (!$successful)
{
    Write-Host ("`n*****`nERROR: COULD NOT UPLOAD $LocalPath to $RemotePath!`n*****`n")
    exit 1
}

Write-Host ("`n*****`nNOTIFICATION: $LocalPath UPLOADED TO $RemotePath!`n*****`n")

exit 0