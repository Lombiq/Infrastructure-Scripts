<#
.Synopsis
    Exports a database of an Azure Web App to Blob Storage snychronously and downloads it to a specified destination in
    a repository.

.DESCRIPTION
    Exports a database of an Azure Web App to Blob Storage snychronously and downloads it to a specified destination in
    a repository.

.EXAMPLE
    Save-AzureWebAppSqlDatabaseToRepository @{
        ResourceGroupName            = "CoolStuffHere"
        WebAppName                   = "NiceApp"
        DatabaseConnectionStringName = "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString"
        StorageConnectionStringName  = "Orchard.Azure.Media.StorageConnectionString"
        ContainerName                = "database"
        RepositoryPath               = "C:\ItsARepo"
        RepositorySubPath            = "Database"
    }
#>


function Save-AzureWebAppSqlDatabaseToRepository
{
    [CmdletBinding()]
    [Alias("iader")]
    Param
    (
        [Alias("ResourceGroupName")]
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide the name of the Resource Group the database's Web App is in.")]
        [string] $DatabaseResourceGroupName,

        [Alias("WebAppName")]
        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the Web App.")]
        [string] $DatabaseWebAppName,

        [Parameter(HelpMessage = "The name of the Web App slot.")]
        [string] $DatabaseSlotName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide a connection string name for the database.")]
        [string] $DatabaseConnectionStringName,

        [Parameter(HelpMessage = "The name of the storage connection string's Resource Group if it differs from the database's.")]
        [string] $StorageResourceGroupName = $DatabaseResourceGroupName,

        [Parameter(HelpMessage = "The name of the storage connection string's Web App if it differs from the database's.")]
        [string] $StorageWebAppName = $DatabaseWebAppName,

        [Parameter(HelpMessage = "The name of the storage connection string's Web App Slot if it differs from the database's.")]
        [string] $StorageSlotName = $DatabaseSlotName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a connection string name for the storage.")]
        [string] $StorageConnectionStringName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide the name of the container in the storage to export the database to.")]
        [string] $ContainerName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a name for the blob in the container to create.")]
        [string] $BlobName,

        [Parameter(Mandatory = $true, HelpMessage = "You need to provide a path to the repository.")]
        [string] $RepositoryPath,

        [Parameter(HelpMessage = "Optional: The relative path to the subfolder in the repository where the database backup will be created.")]
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
            Set-Location "$RepositoryPath"
            git pull
        }
        catch [Exception]
        {
            throw ("Could not pull/update the repository at `"$RepositoryPath`"!")
        }


        Save-AzureWebAppSqlDatabase @{
            DatabaseResourceGroupName    = $DatabaseResourceGroupName
            DatabaseWebAppName           = $DatabaseWebAppName
            DatabaseSlotName             = $DatabaseSlotName
            DatabaseConnectionStringName = $DatabaseConnectionStringName
            StorageResourceGroupName     = $StorageResourceGroupName
            StorageWebAppName            = $StorageWebAppName
            StorageSlotName              = $StorageSlotName
            StorageConnectionStringName  = $StorageConnectionStringName
            ContainerName                = $ContainerName
            BlobName                     = $BlobName
            Destination                  = $destination
        }

        try
        {
            if ([string]::IsNullOrEmpty($CommitMessage))
            {
                $CommitMessage = "Database backup for $DatabaseWebAppName"
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