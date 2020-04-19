param
(
    [Parameter(Mandatory = $true, HelpMessage = "The full path of the Orchard.Web folder of the application.")]
    [string] $PathToOrchardWeb = $(throw "You need to specify the full path of the Orchard.Web folder of the application where Settings.txt file should be created."),

    [Parameter(HelpMessage = "Specifies whether the Settings.txt should be removed (and then recreated) if it exists.")]
    [string] $DeleteIfExists = $true,

    [string] $State = "Running",

    [string] $Themes = "",

    [string] $Modules = "",

    [string] $Name = "Default",

    [string] $DataProvider = "SqlServer",

    [string] $DataConnectionString = "null",

    [string] $DataTablePrefix = "null",

    [string] $RequestUrlHost = "null",

    [string] $RequestUrlPrefix = "null",

    [string] $EncryptionAlgorithm = "AES",

    [Parameter(Mandatory = $true)]
    [string] $EncryptionKey = $(throw "You need to specify the EncryptionKey."),

    [string] $HashAlgorithm = "HMACSHA256",

    [Parameter(Mandatory = $true)]
    [string] $HashKey = $(throw "You need to specify the HashKey.")
)


$settingsPath = "$PathToOrchardWeb\App_Data\Sites\$Name\Settings.txt"
if (Test-Path($settingsPath))
{    
    if (!$DeleteIfExists)
    {
        Write-Host ("`n*****`nWARNING: SETTINGS FILE FOUND, BUT NOT MODIFIED!`n*****`n")
        exit 0
    }

    Remove-Item $settingsPath
}
elseif (!(Test-Path($PathToOrchardWeb) -PathType Container))
{
    Write-Host ("`n*****`nERROR: ORCHARD.WEB FOLDER NOT FOUND AT $Path!`n*****`n")
    exit 1
}
elseif (!(Test-Path "$PathToOrchardWeb\App_Data\Sites\$Name" -PathType Container))
{
    New-Item -ItemType Directory -Force -Path "$PathToOrchardWeb\App_Data\Sites\$Name"
}

$content = @"
State: $State
Themes: $Themes
Modules: $Modules
Name: $Name
DataProvider: $DataProvider
DataConnectionString: $DataConnectionString
DataTablePrefix: $DataTablePrefix
RequestUrlHost: $RequestUrlHost
RequestUrlPrefix: $RequestUrlPrefix
EncryptionAlgorithm: $EncryptionAlgorithm
EncryptionKey: $EncryptionKey
HashAlgorithm: $HashAlgorithm
HashKey: $HashKey
"@

Set-Content $settingsPath $content

Write-Host ("`n*****`nNOTIFICATION: SETTINGS FILE AT $settingsPath (RE)CREATED!`n*****`n")

exit 0