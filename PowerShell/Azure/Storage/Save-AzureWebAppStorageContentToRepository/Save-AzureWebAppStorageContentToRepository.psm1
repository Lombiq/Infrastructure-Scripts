<#
.Synopsis
   Downloads every Container and their Blobs from an Azure Blob Storage.

.DESCRIPTION
   Downloads every Container and their Blobs from an Azure Blob Storage specified by a Connection String of a Web App.

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        RepositoryPath = "C:\ItsARepo"
        RepositorySubPath = "Database"
    }
    Save-AzureWebAppStorageContentToRepository @saveStorageContentParameters

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        ContainerWhiteList = @("media", "stuff")
        RepositoryPath = "C:\ItsARepo"
        RepositorySubPath = "Database"
    }
    Save-AzureWebAppStorageContentToRepository @saveStorageContentParameters

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        ContainerBlackList = @("stuffidontneed")
        RepositoryPath = "C:\ItsARepo"
        RepositorySubPath = "Database"
    }
    Save-AzureWebAppStorageContentToRepository @saveStorageContentParameters

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        ContainerBlackList = @("stuffidontneed")
        FolderWhiteList = @("usefulfolder")
        RepositoryPath = "C:\ItsARepo"
        RepositorySubPath = "Database"
    }
    Save-AzureWebAppStorageContentToRepository @saveStorageContentParameters

.EXAMPLE
    $saveStorageContentParameters = @{
        ResourceGroupName = "CoolStuffHere"
        WebAppName = "NiceApp"
        ConnectionStringName = "SourceStorage"
        ContainerBlackList = @("stuffidontneed")
        FolderWhiteList = @("usefulfolder")
        FolderBlackList = @("uselessfolderintheusefulfolder")
        RepositoryPath = "C:\ItsARepo"
        RepositorySubPath = "Database"
    }
    Save-AzureWebAppStorageContentToRepository @saveStorageContentParameters
#>

function Save-AzureWebAppStorageContentToRepository
{
    [CmdletBinding()]
    [Alias('sascr')]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Resource Group the Web App is in.')]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true, HelpMessage = 'The name of the Azure Web App. The script throws exception if' +
            "the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName,

        [Parameter(HelpMessage = 'The name of the Source Web App slot.')]
        [string] $SlotName,

        [Parameter(Mandatory = $true, HelpMessage = 'The name of a connection string that identifies the Storage' +
            ' Account. The script will exit with error if there is no connection string defined with the name' +
            ' provided for the Production slot of the given Web App.')]
        [string] $ConnectionStringName,

        [Parameter(HelpMessage = 'A list of names of Blob Containers to include. When valid values are provided,' +
            " it cancels out `"ContainerBlackList`".")]
        [string[]] $ContainerWhiteList = @(),

        [Parameter(HelpMessage = 'A list of names of Blob Containers to exclude. When valid values are provided for' +
            " `"ContainerWhiteList`", then `"ContainerBlackList`" is not taken into consideration.")]
        [string[]] $ContainerBlackList = @(),

        [Parameter(HelpMessage = "A list of folder names to include. Applied before `"FolderBlackList`".")]
        [string[]] $FolderWhiteList = @(),

        [Parameter(HelpMessage = "A list of folder names to exclude. Applied after `"FolderWhiteList`".")]
        [string[]] $FolderBlackList = @(),

        [Parameter(Mandatory = $true, HelpMessage = 'The path of the root of the repository where the storage files should be downloaded.')]
        [string] $RepositoryPath,

        [Parameter(HelpMessage = 'Optional: The relative path to the subfolder in the repository where the storage files should be downloaded.')]
        [string] $RepositorySubPath,

        [Parameter(HelpMessage = 'Optional: Override the default commit message.')]
        [string] $CommitMessage = ''
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
            Set-Location "$RepositoryPath"
            git pull
        }
        catch [Exception]
        {
            throw ("Could not pull/update the repository at $RepositoryPath!")
        }



        $saveStorageContentParameters = @{
            ResourceGroupName = $ResourceGroupName
            WebAppName = $WebAppName
            SlotName = $SlotName
            ConnectionStringName = $ConnectionStringName
            Destination = $destination
            ContainerWhiteList = $ContainerWhiteList
            ContainerBlackList = $ContainerBlackList
            FolderWhiteList = $FolderWhiteList
            FolderBlackList = $FolderBlackList
        }
        Save-AzureWebAppStorageContent @saveStorageContentParameters



        Rename-ChildItemsToAsciiRecursively -Path $destination

        try
        {
            if ([string]::IsNullOrEmpty($CommitMessage))
            {
                $CommitMessage = "Storage backup for $WebAppName"
            }

            Set-Location "$RepositoryPath"
            git add .
            git commit --all --message="$CommitMessage"
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