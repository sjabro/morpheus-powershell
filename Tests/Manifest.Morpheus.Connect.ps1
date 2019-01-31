$version = Read-Host "Enter Release Version"

$manifest = @{
    Path              = "C:\Users\Bunge\OneDrive\Document\GitHub\morpheus-powershell\Module\Morpheus.Connect\$version\Morpheus.Connect.psd1"
    RootModule        = 'Morpheus.Connect.psm1' 
    Author            = 'Morpheus Data'
    CompanyName       = 'Morpheus Data'
    Description       = 'Commandlets for API interaction with a Morpheus environment'
    PowerShellVersion = '4.0'
    FunctionsToExport   = @('Connect-Morpheus')
    VariablesToExport = '*'
    ModuleVersion     = "$version"
}

New-ModuleManifest @manifest