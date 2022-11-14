param
(
    [Parameter(Mandatory = $true, HelpMessage = "The URL of the file to download.")]
    [string] $FileLocationUrl = $(throw "You need to specify an URL to download from."),

    [Parameter(Mandatory = $true, HelpMessage = "The name of the downloaded file.")]
    [string] $FileName = $(throw "You need to specify the name of the downloaded file."),

    [Parameter(HelpMessage = "The destination to download to file to. When not specified, the file will be downloaded to the current user's Downloads folder.")]
    [string] $Destination = "$env:USERPROFILE\Downloads"
)

$fullFilePath = "$Destination\$FileName"

if (Test-Path($Destination))
{
    try
    {
        (New-Object Net.WebClient).DownloadFile($FileLocationUrl, $fullFilePath)
    }
    catch [Exception]
    {
        Write-Host ("`n*****`ERROR: COULD NOT DOWNLOAD $FileLocationUrl TO $fullFilePath!`n")
        Write-Host $_.Exception.Message
        Write-Host ("*****`n")
	    exit 1
    }
}
else
{
    Write-Host ("`n*****`nERROR: DESTINATION FOLDER $Destination NOT FOUND!`n*****`n")
    exit 1
}

$Global:DownloadedFilePath = $fullFilePath
Write-Output ("`n*****`nNOTIFICATION: SUCCESSFULLY DOWNLOADED FILE FROM $FileLocationUrl TO $fullFilePath.`n*****`n")
exit 0