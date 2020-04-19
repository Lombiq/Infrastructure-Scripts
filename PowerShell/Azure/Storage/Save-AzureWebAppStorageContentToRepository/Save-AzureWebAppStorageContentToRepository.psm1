<#
.Synopsis
   Downloads every Container and their Blobs from an Azure Blob Storage.

.DESCRIPTION
   Downloads every Container and their Blobs from an Azure Blob Storage specified by a Connection String of a Web App.

.EXAMPLE
   Save-AzureWebAppStorageContent -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -ConnectionStringName "Orchard.Azure.Media.StorageConnectionString" -Destination "D:\Backup"

.EXAMPLE
   Save-AzureWebAppStorageContent -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -ConnectionStringName "takemetothestorage" -Destination "D:\Backup" -ContainerWhiteList @("media", "stuff")

.EXAMPLE
   Save-AzureWebAppStorageContent -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -ConnectionStringName "storage" -ContainerBlackList @("stuffidontneed") -RepositoryPath "C:\ItsARepo" -RepositorySubPath "Database"

.EXAMPLE
   Save-AzureWebAppStorageContent -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -ConnectionStringName "storage" -ContainerBlackList @("stuffidontneed") -FolderWhiteList @("usefulfolder") -RepositoryPath "C:\ItsARepo" -RepositorySubPath "Database"

.EXAMPLE
   Save-AzureWebAppStorageContent -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -ConnectionStringName "storage" -ContainerBlackList @("stuffidontneed") -FolderWhiteList @("usefulfolder") -FolderBlackList @("uselessfolderintheusefulfolder") -RepositoryPath "C:\ItsARepo" -RepositorySubPath "Database"
#>


function Save-AzureWebAppStorageContentToRepository
{
    [CmdletBinding()]
    [Alias("sascr")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the Storage Account. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $ConnectionStringName = $(throw "You need to provide a connection string name for the Storage Account."),

        [Parameter(HelpMessage = "A list of names of Blob Containers to include. When valid values are provided, it cancels out `"ContainerBlackList`".")]
        [string[]] $ContainerWhiteList = @(),

        [Parameter(HelpMessage = "A list of names of Blob Containers to exclude. When valid values are provided for `"ContainerWhiteList`", then `"ContainerBlackList`" is not taken into consideration.")]
        [string[]] $ContainerBlackList = @(),

        [Parameter(HelpMessage = "A list of folder names to include. Applied before `"FolderBlackList`".")]
        [string[]] $FolderWhiteList = @(),

        [Parameter(HelpMessage = "A list of folder names to exclude. Applied after `"FolderWhiteList`".")]
        [string[]] $FolderBlackList = @(),

        [Parameter(Mandatory = $true, HelpMessage = "The path of the root of the repository where the storage files should be downloaded.")]
        [string] $RepositoryPath = $(throw "You need to provide a path to the repository."),

        [Parameter(HelpMessage = "Optional: The relative path to the subfolder in the repository where the storage files should be downloaded.")]
        [string] $RepositorySubPath,

        [Parameter(HelpMessage = "Optional: Override the default commit message.")]
        [string] $CommitMessage = ""
    )

    Process
    {
        if (!(Test-Path $RepositoryPath))
        {
            throw ("The folder `"$RepositoryPath`" can not be found!")
        }
                
        $destination = $RepositoryPath

        if (!([string]::IsNullOrEmpty($RepositorySubPath)))
        {
            $destination += "\$RepositorySubPath"

            if (!(Test-Path $destination))
            {
                New-Item -ItemType Directory -Path $destination -Force
            }
        }



        try
        {
            cd "$RepositoryPath"
            git fetch origin
            git checkout master
        }
        catch [Exception]
        {
            throw ("Could not pull/update the repository at $RepositoryPath!")
        }

        
        
        Save-AzureWebAppStorageContent `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $WebAppName `
            -ConnectionStringName $ConnectionStringName `
            -Destination $destination `
            -ContainerWhiteList $ContainerWhiteList `
            -ContainerBlackList $ContainerBlackList `
            -FolderWhiteList $FolderWhiteList `
            -FolderBlackList $FolderBlackList



        RecursiveRenameToAscii -Path $destination

        try
        {
            if ([string]::IsNullOrEmpty($CommitMessage))
            {
                $CommitMessage = "Storage backup for $WebAppName"
            }

            cd "$RepositoryPath"
            git add .
            git commit --all -R --message="$CommitMessage"
            git push origin master

            if (-not [string]::IsNullOrEmpty((git log origin/master..master)))
            {
                throw
            }
        }
        catch [Exception]
        {
            throw ("Could not commit/push to the repository at `"$RepositoryPath`"!")
        }
    }
}



function RecursiveRenameToAscii
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string] $Path
    )

    Process
    {
        foreach ($item in Get-ChildItem $Path)
        {
            if ($item.PSIsContainer)
            {
                RecursiveRenameToAscii -Path $item.FullName
            }

            $asciiName = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($item.Name)).Replace('?', '_')

            if ($item.Name -ne $asciiName)
            {
                Write-Host ("Renaming `"" + $item.FullName + "`".")
                $item | Rename-Item -NewName $asciiName
            }
        }
    }
}