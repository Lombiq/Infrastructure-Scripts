param
(
    [Parameter(Mandatory = $true, HelpMessage = "The full path to the .zip file to extract.")]
    [string] $FilePath = $(throw "You need to specify a .zip file extract."),

    [Parameter(Mandatory = $true, HelpMessage = "The destination where the .zip file should be extracted.")]
    [string] $Destination = $(throw "You need to specify a folder to extract the .zip file to."),

    [Parameter(HelpMessage = "When enabled, the .zip file will be deleted after it's extracted.")]
    [switch] $DeleteZipAfterExtract
)

if (Test-Path($FilePath))
{
    if (-Not (Test-Path($Destination)))
    {
        New-Item -ItemType Directory -Path $Destination -Force
    }

    try
    {
        $shellApplication = New-Object -ComObject Shell.Application
        $shellApplication.NameSpace($Destination).CopyHere($shellApplication.NameSpace($FilePath).Items(), 16)
    }
    catch [Exception]
    {
        Write-Host ("`n*****`ERROR: COULD NOT EXTRACT $FilePath TO $Destination!`n")
        Write-Host $_.Exception.Message
        Write-Host ("*****`n")
	    exit 1
    }
}
else
{
    Write-Host ("`n*****`nERROR: $FilePath NOT FOUND!`n*****`n")
    exit 1
}

if ($DeleteZipAfterExtract.IsPresent)
{
    Remove-Item $FilePath -Force
    Write-Output ("`n*****`nNOTIFICATION: $FilePath DELETED.`n*****`n")
}

Write-Output ("`n*****`nNOTIFICATION: SUCCESSFULLY EXTRACTED $FilePath TO $Destination.`n*****`n")
exit 0