# `Hosting - Azure PowerShell` modules readme



## Overview

Custom `PowerShell` modules interacting with `Azure` services through `PowerShell` modules provided by the `Azure PowerShell SDK`, which you can install from the [Web Platform Installer](https://www.microsoft.com/web/downloads/platform.aspx).

## Get started

To be able to interact with `Azure` resources, you need to have an `Azure Publish Settings` file imported to your system that contains the necessary keys to access the subscriptions. Visit the [subscription file download page](https://manage.windowsazure.com/publishsettings), where you will be presented with the list of Active Directories you have access to. You can download and import a file for each `Active Directory` separately using the following command, which will give you access to each subscription contained within that `Active Directory` (you remove the subscriptions you don't need from the file):
```
Import-AzurePublishSettingsFile -PublishSettingsFile "C:\Path\To\File\lombiq.publishsettings"
```

## Commandlets

### Subscriptions

#### Confirm-AzureSubscription

Checks whether the specified subscription's authentication information is imported on the system. If the subscription is available, it will be set as the default subscription for the session and its details will be returned.


### Web Apps

#### Confirm-AzureWebApp

Checks whether the specified Web App exists on the given subscription; if it does, its details will be returned.

Dependencies: Confirm-AzureSubscription.

#### Get-AzureWebAppWrapper

Returns the details of a Web App (with a retry logic added, in case a temporary error prevents accessing the Azure API).

Dependencies: Confirm-AzureWebApp.

#### Test-AzureWebApp

Pings a Web App through its first enabled hostname.

Dependencies: Get-AzureWebAppWrapper, Test-Url (Utilities).

#### Get-AzureWebAppConnectionString

Returns a connection string stored among the settings of a Web App.

Dependencies: Get-AzureWebAppWrapper.

#### Start-AzureWebAppSlot

Starts the specified deployment Slot of a Web App.

Dependencies: Confirm-AzureWebApp.

#### Stop-AzureWebAppSlot

Stops the specified deployment Slot of a Web App.

Dependencies: Confirm-AzureWebApp.

#### Switch-AzureWebAppSlots

Provided a Web App and a source and destination deployment Slot, it performs the necessary and App Settings and Connection Strings transformations on the source slot for the destination environment, then swaps the Slots and configures the (new) source Slot for the source environment's settings. In case of a failure in updating the settings of the source Slot, it will be stopped.

Dependencies: Get-AzureWebAppWrapper, Stop-AzureWebAppSlot


### Blob Storage

#### Get-AzureWebAppStorageConnection

Provided a name of a connection string corresponding to a Blob Storage, it will return the Name and Key of the Storage Account for other modules to be able connect to it.

Dependencies: Get-AzureWebAppConnectionString.


### SQL Databases

#### Get-AzureWebAppSqlDatabaseConnection

Given the name of a connection string, it will return all the necessary information extracted from the connection string to be able to connect to a SQL Azure database.

Dependencies: Get-AzureWebAppConnectionString.

#### Get-AzureWebAppSqlDatabase

Given the name of a connection string, it will return all the contextual information regarding a SQL Azure database.

Dependencies: Get-AzureWebAppSqlDatabaseConnection.

#### Remove-AzureWebAppSqlDatabase

Given the name of a connection string, it will delete the corresponding SQL Azure database.

Dependencies: Get-AzureWebAppSqlDatabaseConnection.

#### Start-AzureWebAppSqlDatabaseCopy

Given a connection string name for a source and a destination SQL Azure database, it will delete the database corresponding to the destination (if it exists) and start a one-time, asynchronous database copy operation from the source to the destination.

Dependencies: Get-AzureWebAppSqlDatabase, Remove-AzureWebAppSqlDatabase.

#### Invoke-AzureWebAppSqlDatabaseCopy

Given a connection string name for a source and a destination SQL Azure database, it will invoke a one-time, synchronous database copy operation from the source to the destination: after starting the copy operation it will periodically monitor the progress until it's finished.

Dependencies: Start-AzureWebAppSqlDatabaseCopy.

#### Start-AzureWebAppSqlDatabaseExport

Given a connection string name for a SQL Azure database and a Storage Account, it will invoke an asynchronous export operation on the database into the specified blob in Blob Storage.

Dependencies: Get-AzureWebAppSqlDatabaseConnection, Get-AzureWebAppStorageConnection.

#### Invoke-AzureWebAppSqlDatabaseExport

Given a connection string name for a SQL Azure database and a Storage Account, it will invoke a synchronous export operation on the database into the specified blob in Blob Storage: after starting the export operation it will periodically monitor the progress until it's finished.

Dependencies: Start-AzureWebAppSqlDatabaseExport.

#### Save-AzureWebAppSqlDatabase

Starts a synchronous database export operation and downloads the exported database to the local file system to a specified location.

Dependencies: Invoke-AzureWebAppSqlDatabaseExport.

#### Save-AzureWebAppSqlDatabaseToRepository

Saves and pushes an exported SQL Azure database into a specified repository.

Dependencies: Save-AzureWebAppSqlDatabase.