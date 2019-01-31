The Morpheus API is a very robust API that provides a lot of functionality for both self-service provisioning across many clouds as well as visibility into existing infrastructure. This provides a set of cmdlets for Powershell to make it easier to access Data Objects in a familiar manner for PowerShell users.

## Installation

1. Download all Module folders located under "Modules"
2. Move contents into one of your `$env:PSModulePath` paths.
(Typically `C:\Program Files\WindowsPowerShell\Modules` will suffice)
		
## Usage

```powershell
Connect-Morpheus [-URL] <String> [-Username] <String> [-Password] <String>
```
	
Several Additional Commandlets Are Available:

```powershell
Get-Command -Module Morpheus*
```

## Contributions

This is an early release of Powershell Commandlets that map to the Morpheus API and third party contributions are most welcome. For More Information of the Morpheus API Visit [Morpheus Data](https://www.morpheusdata.com)
