# Hosting - Infrastructure Scripts readme

Scripts - PowerShell, mostly - for automating processes within a continuous integration and deployment environment of a Hosting Suite-integrated Orchard application.

## Overview

The Lombiq Hosting Suite consists of Orchard modules (designed to enhance several parts and features of an Orchard application) and automation scripts to drive the build and deployment processes of an Orchard application.

The scripts are mostly PowerShell modules that can be reused anywhere on the system after they are "installed" by adding the root of the Infrastructure Scripts folder to `$PSModulePath`. Of course, there's a script for that: See `Utilities\AddPathToPSModulePath.ps1`.

Infrastructure Scripts is not tied to any specific CI system, but in terms of the hosting environment they rely on Azure features, meaning that most of it **depends on the Azure PowerShell SDK**. Azure services are usually accessed by defining the name of the Azure subscription, the name of an Azure Web App (and optionally the name of the deployment Slot) and other parameters specific to the operation (in many cases, one of these is the name of a connection string for accessing a resource stored among the settings of the Web App). 

The Infrastructure Scripts does not require the Orchard modules of the Hosting Suite to be able to function (and vice versa), although the two together work best for a seamless developer experience.

## Folder structure and components

- `Utility` (submodule): A few useful scripts/modules for everyday use (not closely related to hosting). [This component has its own readme](Utility/Readme.md).
- `PowerShell`: The heart and soul of Infrastructure Scripts (see the `PowerShell` subfolder), divided into these sub-features:
	- `Azure`: These modules interact directly with Azure services, such as Blob Storages, Databases and Web Apps. [This component has its own readme](PowerShell/Azure/Readme.md)
	- `Hosting Suite`: These modules interact directly with Orchard modules of the Hosting Suite through WebAPI, e.g. for starting/executing maintenances. [This component has its own readme](PowerShell/HostingSuite/Readme.md).
	- `Utilities`: Modules and plain scripts for simple tasks, such as sending a ping request to a URL or extracting a .zip file.

## Contributing and support

Bug reports, feature requests, comments, questions, code contributions and love letters are warmly welcome. You can send them to us via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.
