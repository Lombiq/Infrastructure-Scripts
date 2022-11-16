# Hosting - Hosting Suite PowerShell modules readme



PowerShell modules related to the Lombiq Hosting Suite.


## Maintenances

### Invoke-Maintenance

Invokes the execution of a given maintenance through Web API asynchronously.

### Get-Maintenance

Retrieves the status of a given maintenance through Web API.

### Start-Maintenance

Invokes the execution of a given maintenance through Web API synchronously: after invoking the maintenance execution it will periodically monitor the progress of the maintenance until it's complete.

Dependencies: Invoke-Maintenance, Get-Maintenance.


## Other

### New-RootConnectionStringFile

Retrieves a connection string defined by its name from the settings of an Azure Web App and writes it into a file (with the path and filename specified).

Dependencies: Get-AzureWebAppConnectionString (Azure).