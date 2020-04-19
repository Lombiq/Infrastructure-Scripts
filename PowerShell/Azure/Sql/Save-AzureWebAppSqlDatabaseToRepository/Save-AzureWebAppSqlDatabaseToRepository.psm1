<#
.Synopsis
   Exports a database of an Azure Web App to Blob Storage snychronously and downloads it to a specified destination in a repository.

.DESCRIPTION
   Exports a database of an Azure Web App to Blob Storage snychronously and downloads it to a specified destination in a repository.

.EXAMPLE
   Save-AzureWebAppSqlDatabaseToRepository -ResourceGroupName "CoolStuffHere" -WebAppName "NiceApp" -DatabaseConnectionStringName "Lombiq.Hosting.ShellManagement.ShellSettings.RootConnectionString" -StorageConnectionStringName "Orchard.Azure.Media.StorageConnectionString" -ContainerName "database" -RepositoryPath "C:\ItsARepo" -RepositorySubPath "Database"
#>


function Save-AzureWebAppSqlDatabaseToRepository
{
    [CmdletBinding()]
    [Alias("iader")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group the Web App is in.")]
        [string] $ResourceGroupName = $(throw "You need to provide the name of the Resource Group."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Web App. The script throws exception if the Web App doesn't exist on the given subscription.")]
        [string] $WebAppName = $(throw "You need to provide the name of the Web App."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the database. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $DatabaseConnectionStringName = $(throw "You need to provide a connection string name for the database."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a connection string that identifies the storage to export the database to. The script will exit with error if there is no connection string defined with the name provided for the Production slot of the given Web App.")]
        [string] $StorageConnectionStringName = $(throw "You need to provide a connection string name for the storage."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of a container in the storage to export the database to.")]
        [string] $ContainerName = $(throw "You need to provide a name for the container."),

        [Parameter(Mandatory = $true, HelpMessage = "The name of the blob in the container to create.")]
        [string] $BlobName = $(throw "You need to provide a name for the blob."),

        [Parameter(Mandatory = $true, HelpMessage = "The path of the root of the repository where the database backup will be created.")]
        [string] $RepositoryPath = $(throw "You need to provide a path to the repository."),

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
            cd "$RepositoryPath"
            git fetch origin
            git checkout master
        }
        catch [Exception]
        {
            throw ("Could not pull/update the repository at `"$RepositoryPath`"!")
        }



        Save-AzureWebAppSqlDatabase -ResourceGroupName $ResourceGroupName -WebAppName $WebAppName -DatabaseConnectionStringName $DatabaseConnectionStringName `
            -StorageConnectionStringName $StorageConnectionStringName -ContainerName $ContainerName -BlobName $BlobName -Destination $destination



        try
        {
            if ([string]::IsNullOrEmpty($CommitMessage))
            {
                $CommitMessage = "Database backup for $WebAppName"
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