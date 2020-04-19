param
(
    [Parameter(Mandatory = $true, HelpMessage = "The URL of the file to download.")]
    [string] $FileLocationUrl = $(throw "You need to specify an URL to download the file from."),

    [Parameter(Mandatory = $true, HelpMessage = "The destination to download to exract the .zip file to.")]
    [string] $Destination = $(throw "You need to specify the folder to extract the .zip file to.")
)

$downloadFileScriptPath = "$PSScriptRoot\DownloadFile.ps1"
if (Test-Path($downloadFileScriptPath))
{
    $guid = [guid]::NewGuid()
    & $downloadFileScriptPath -FileLocationUrl $FileLocationUrl -FileName "$guid.zip"
    if ($LASTEXITCODE -ne 0)
    {
        exit $LASTEXITCODE
    }
}
else
{
    Write-Host ("`n*****`nERROR: SCRIPT FILE NOT FOUND AT $downloadFileScriptPath!`n*****`n")
    exit 1
}

$filePath = $Global:DownloadedFilePath
if (-Not (Test-Path $filePath))
{
    Write-Host ("`n*****`nERROR: $filePath NOT FOUND!`n*****`n")
    exit 1
}

$extractZipScriptPath = "$PSScriptRoot\ExtractZip.ps1"
if (Test-Path($downloadFileScriptPath))
{
    & $extractZipScriptPath -FilePath $filePath -Destination $Destination -DeleteZipAfterExtract
    if ($LASTEXITCODE -ne 0)
    {
        exit $LASTEXITCODE
    }
}
else
{
    Write-Host ("`n*****`nERROR: SCRIPT FILE NOT FOUND AT $extractZipScriptPath!`n*****`n")
    exit 1
}

exit 0