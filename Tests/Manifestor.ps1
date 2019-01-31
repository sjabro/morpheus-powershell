$version = Read-Host "Enter Release Version"

#Morpheus.Connect
    $manifest = @{}
    $manifest = @{
        Path              = "C:\Users\Bunge\OneDrive\Document\GitHub\morpheus-powershell\Module\Morpheus.Connect\$version\Morpheus.Connect.psd1"
        RootModule        = 'Morpheus.Connect.psm1' 
        Author            = 'Morpheus Data'
        CompanyName       = 'Morpheus Data'
        Description       = 'Commandlets for API interaction with a Morpheus environment'
        PowerShellVersion = '4.0'
        FunctionsToExport = 'Connect-Morpheus'
        VariablesToExport = '*'
        ModuleVersion     = "$version"
    }

    New-ModuleManifest @manifest

#Morpheus.Get
    $manifest = @{}
    $manifest = @{
        Path              = "C:\Users\Bunge\OneDrive\Document\GitHub\morpheus-powershell\Module\Morpheus.Get\$version\Morpheus.Get.psd1"
        RootModule        = 'Morpheus.Get.psm1' 
        Author            = 'Morpheus Data'
        CompanyName       = 'Morpheus Data'
        Description       = 'Commandlets for API interaction with a Morpheus environment'
        PowerShellVersion = '4.0'
        FunctionsToExport = 'Get-*'
        VariablesToExport = '*'
        RequiredModules   = @(
            @{"ModuleName"="Morpheus.Connect";"ModuleVersion"="1.0"}      
            )
        ModuleVersion     = "$version"
        FormatsToProcess  = @('Morpheus.Get.Format.ps1xml')
    }

    New-ModuleManifest @manifest

#Morpheus.PShell
    $manifest = @{}
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

#Morpheus.Remove
    $manifest = @{}
    $manifest = @{
        Path              = "C:\Users\Bunge\OneDrive\Document\GitHub\morpheus-powershell\Module\Morpheus.Remove\$version\Morpheus.Remove.psd1"
        RootModule        = 'Morpheus.Remove.psm1' 
        Author            = 'Morpheus Data'
        CompanyName       = 'Morpheus Data'
        Description       = 'Commandlets for API interaction with a Morpheus environment'
        PowerShellVersion = '4.0'
        FunctionsToExport = 'Remove-*'
        VariablesToExport = '*'
        RequiredModules   = @(
            @{"ModuleName"="Morpheus.Connect";"ModuleVersion"="$version"},
            @{"ModuleName"="Morpheus.Get";"ModuleVersion"="$version"}      
            )
        ModuleVersion     = "$version"
    }

    New-ModuleManifest @manifest