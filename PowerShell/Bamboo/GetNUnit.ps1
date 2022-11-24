param
(
    [Parameter(HelpMessage = "The URL to the NUnit .zip file.")]
    [string] $NUnitZipURL = "http://github.com/nunit/nunitv2/releases/download/2.6.4/NUnit-2.6.4.zip",

    [Parameter(HelpMessage = "The destination to install NUnit to.")]
    [string] $Destination = "C:\Program Files (x86)\NUnit"
)

$downloadAndExtractZipScriptPath = "$PSScriptRoot\..\Utilities\DownloadAndExtractZip.ps1"
if (Test-Path($downloadAndExtractZipScriptPath))
{
    & $downloadAndExtractZipScriptPath -FileLocationUrl $NUnitZipURL -Destination $Destination
    if ($LASTEXITCODE -ne 0)
    {
        exit $LASTEXITCODE
    }
}
else
{
    Write-Output ("`n*****`nERROR: SCRIPT FILE NOT FOUND AT $downloadAndExtractZipScriptPath!`n*****`n")
    exit 1
}

$nunitVersionFolderName = (Get-ChildItem $Destination -Directory)[0]
$nunitVersionFolderNameSlash = $nunitVersionFolderName.ToString() + "\"
$nunitVersionFolderPath = "$Destination\$nunitVersionFolderName"

Get-ChildItem $nunitVersionFolderPath -Recurse | ForEach-Object { Move-Item -Path $PSItem.FullName -Destination $PSItem.FullName.Replace($nunitVersionFolderNameSlash, "") -Force }
Remove-Item $nunitVersionFolderPath -Force

exit 0