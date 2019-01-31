$version = Read-Host "Enter Release Version"

$manifest = @{
    Path              = "C:\Users\Bunge\OneDrive\Document\GitHub\morpheus-powershell\Module\Morpheus.PShell\$version\Morpheus.PShell.psd1"
    Author            = 'Morpheus Data'
    CompanyName       = 'Morpheus Data'
    Description       = 'Commandlets for API interaction with a Morpheus environment'
    PowerShellVersion = '4.0'
    DotNetFrameworkVersion = '4.5'
    FunctionsToExport = '*'
    VariablesToExport = '*'
    RequiredModules   = @(
        @{"ModuleName"="Morpheus.Connect";"ModuleVersion"="1.0"},   
        @{"ModuleName"="Morpheus.Get";"ModuleVersion"="1.0"},
        @{"ModuleName"="Morpheus.Remove";"ModuleVersion"="1.0"}      
        )
    ModuleVersion     = "$version"
}

New-ModuleManifest @manifest