Installation:
	-Copy contents from the latest release under "Modules"
	-Create "Morpheus" folder and place files in one of your '$env:PSModulePath' paths.
		--Typically 'C:\Program Files\WindowsPowerShell\Modules'
		
Usage:
	-Connect to a Morpheus Appliance
		--"Connect-Morpheus [-URL] <String> [-Username] <String> [[-Password] <Object>] [<CommonParameters>]"
	
Additional Commandlets:
	-Output all commandlets available
		--"Get-Command -Module Morpheus*"
