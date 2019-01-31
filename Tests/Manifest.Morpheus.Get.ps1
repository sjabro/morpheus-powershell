$version = Read-Host "Enter Release Version"

$manifest = @{
    Path              = "C:\Users\Bunge\OneDrive\Document\GitHub\morpheus-powershell\Module\Morpheus.Get\$version\Morpheus.Get.psd1"
    RootModule        = 'Morpheus.Get.psm1' 
    Author            = 'Morpheus Data'
    CompanyName       = 'Morpheus Data'
    Description       = 'Commandlets for API interaction with a Morpheus environment'
    PowerShellVersion = '4.0'
    FunctionsToExport   = @('Get-*')
    VariablesToExport = '*'
    RequiredModules   = @(
        @{"ModuleName"="Morpheus.Connect";"ModuleVersion"="1.0"}      
        )
    ModuleVersion     = "$version"
    FormatsToProcess  = @('Morpheus.Get.Format.ps1xml')
}

New-ModuleManifest @manifest