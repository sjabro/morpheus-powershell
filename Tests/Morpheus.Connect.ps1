New-Variable -Name URL
New-Variable -Name Header

Function Connect-Morpheus {
    <#
    .Synopsis
       Makes connection to your Morpheus Appliance.
    .DESCRIPTION
       A connection is made to your Morpheus Appliance via port 443.  All calls are made to this connection
       object until the terminal is closed.
    .EXAMPLE
       Connect-Morpheus -URL test.morpheus.com
    .EXAMPLE
       Connect-Morpheus -URL https://test.morpheus.com -Username TestUser
    .EXAMPLE
       Connect-Morpheus -URL https://test.morpheus.com -Username TestUser -Password S@mplePa55
    #>


    ####  User Variables  ####
    Param(
        [Parameter(Mandatory=$true)][string]$URL,        
        [Parameter(Mandatory=$true)][string]$Username,
        $Password
        )
    if (!$URL.StartsWith('https://')) {
        $URL = ('https://' + $URL)
        }

    $Script:URL = $URL

    if (-not($Password)) {
        $Password = Read-host 'Enter Password' -AsSecureString
        $PlainTextPassword= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( ($Password) ))
        }
    ELSE {
        $PlainTextPassword = $Password
        }

    Try {
        $Errors = $null
        ####  Morpheus Variables  ####
        $Body = "username=$Username&password=$PlainTextPassword"
        $AuthURL = "/oauth/token?grant_type=password&scope=write&client_id=morph-customer"

        ####  Create User Token   ####
        $Token = Invoke-WebRequest -Method POST -Uri ($URL + $AuthURL) -Body $Body | select -ExpandProperty content|
            ConvertFrom-Json | select -ExpandProperty access_token
        $Script:Header = @{
            "Authorization" = "BEARER $Token"
            }
        }

    Catch {
        $Errors = $true
        Write-Host "Failed to authenticate credentials" -ForegroundColor Red
        }
    Finally {
        if (!$Errors) {
            Write-Host "Successfully connected to $URL.
Use `"Get-Command -Module Morpheus`" to discover available commands." -ForegroundColor Yellow
            }
        }
    }

Export-ModuleMember -Variable URL,Header