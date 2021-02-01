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


    ####  User Inputs  ####
    [CmdletBinding(DefaultParameterSetName = 'BasicAuth')]
    Param(
        ### Primary URL for connectivity
        [Alias("Server")]
        [Parameter(ParameterSetName = "BasicAuth", Mandatory=$true)]
        [Parameter(ParameterSetName = 'CredAuth', Mandatory=$true)]
        [string]$URL,        
        [Parameter(ParameterSetName = "BasicAuth", Mandatory=$true)]
        [string]$Username,
        [Parameter(ParameterSetName = "BasicAuth")]
        $Password,
        [Parameter(ParameterSetName = 'CredAuth', Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        $Credential
        )
    
    ## Ensure https:// in URL
    if (!$URL.StartsWith('https://')) {
        $URL = ('https://' + $URL)
        }
    
    ## Export global vars
    $Global:URL = $URL
    
    ## If Credential switch not used providing a PS credential, build the credential from user input user/pass combo
    if (!($Credential)){
        if (!($Password)){
            $Password = Read-Host "Enter password for $($Username)" -AsSecureString
        }else{
            $Password = $Password | ConvertTo-SecureString -AsPlainText -Force
        }
        $Credential = New-Object System.Management.Automation.PSCredential($Username,$Password)
    }

    # Create the body for the post
    $postBody = @{
        grant_type = "password"
        client_id = "morph-api"
        scope = "write"
        username = $Credential.UserName
        password = $Credential.GetNetworkCredential().Password
        } 

    ## Get that token
    Try {
        $err = $null
        ####  Morpheus Variables  ####
        $AuthURL = "/oauth/token"

        ####  Create User Token   ####
        $call = Invoke-WebRequest -SkipCertificateCheck -Method POST -Uri ($URL + $AuthURL) -Body $postBody -ErrorVariable err -ErrorAction SilentlyContinue 
        $Token = ($call | Select-Object -ExpandProperty content | ConvertFrom-Json -Depth 10).access_token
        
        $Global:Header = @{
            "Authorization" = "BEARER $Token"
            }
        }

    Catch [Exception]{
        if ($err){
            Write-Host $err.message -ForegroundColor Red
            Break
            }
        }
    Finally {
        if (!$err) {
            Write-Host "Successfully connected to $URL. 
Use `"Get-Command -Module Morpheus`" to discover available commands." -ForegroundColor Yellow
            }
        }
    }
