#Set Environment Vars
$FormatEnumerationLimit = 8
$Host.PrivateData.ProgressBackgroundColor="DarkCyan"
$Host.PrivateData.ProgressForegroundColor="Black"


#  █████  ██    ██ ████████ ██   ██ ███████ ███    ██ ████████ ██  ██████  █████  ████████ ██  ██████  ███    ██ 
# ██   ██ ██    ██    ██    ██   ██ ██      ████   ██    ██    ██ ██      ██   ██    ██    ██ ██    ██ ████   ██ 
# ███████ ██    ██    ██    ███████ █████   ██ ██  ██    ██    ██ ██      ███████    ██    ██ ██    ██ ██ ██  ██ 
# ██   ██ ██    ██    ██    ██   ██ ██      ██  ██ ██    ██    ██ ██      ██   ██    ██    ██ ██    ██ ██  ██ ██ 
# ██   ██  ██████     ██    ██   ██ ███████ ██   ████    ██    ██  ██████ ██   ██    ██    ██  ██████  ██   ████ 


#  ██████  ██████  ███████ ██████   █████  ████████ ██  ██████  ███    ██ ███████ 
# ██    ██ ██   ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ████   ██ ██      
# ██    ██ ██████  █████   ██████  ███████    ██    ██ ██    ██ ██ ██  ██ ███████ 
# ██    ██ ██      ██      ██   ██ ██   ██    ██    ██ ██    ██ ██  ██ ██      ██ 
#  ██████  ██      ███████ ██   ██ ██   ██    ██    ██  ██████  ██   ████ ███████ 


# ██████  ██████   ██████  ██    ██ ██ ███████ ██  ██████  ███    ██ ██ ███    ██  ██████  
# ██   ██ ██   ██ ██    ██ ██    ██ ██ ██      ██ ██    ██ ████   ██ ██ ████   ██ ██       
# ██████  ██████  ██    ██ ██    ██ ██ ███████ ██ ██    ██ ██ ██  ██ ██ ██ ██  ██ ██   ███ 
# ██      ██   ██ ██    ██  ██  ██  ██      ██ ██ ██    ██ ██  ██ ██ ██ ██  ██ ██ ██    ██ 
# ██      ██   ██  ██████    ████   ██ ███████ ██  ██████  ██   ████ ██ ██   ████  ██████  


# ██ ███    ██ ███████ ██████   █████  ███████ ████████ ██████  ██    ██  ██████ ████████ ██    ██ ██████  ███████ 
# ██ ████   ██ ██      ██   ██ ██   ██ ██         ██    ██   ██ ██    ██ ██         ██    ██    ██ ██   ██ ██      
# ██ ██ ██  ██ █████   ██████  ███████ ███████    ██    ██████  ██    ██ ██         ██    ██    ██ ██████  █████   
# ██ ██  ██ ██ ██      ██   ██ ██   ██      ██    ██    ██   ██ ██    ██ ██         ██    ██    ██ ██   ██ ██      
# ██ ██   ████ ██      ██   ██ ██   ██ ███████    ██    ██   ██  ██████   ██████    ██     ██████  ██   ██ ███████


Function Set-MDGroup {
    <#
    .Synopsis
       Set Selected Group
    .DESCRIPTION
       Updates a Morpheus Group
    #>
    [cmdletbinding()]
    Param (
        [Parameter()]
        [Switch]
        $enable,
        [Parameter()]
        [Switch]
        $disable,       
        # # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        $body = @{}

    }

    PROCESS {

        if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
            $object = Get-UpdateObjectData $InputObject -Verbose
        }else{
            $object = Get-UpdateObjectData -InputObject $InputObject
        }

        if ($disable){
            $InputObject.Active = "False"
        }

        if ($enable){
            $InputObject.Active = "True"
        }

        $API = $object.api
        Write-Verbose "$(Get-Date): API Endpoint set to $($API)"
        $construct = $object.construct
        Write-Verbose "$(Get-Date): Construct set to $($construct)"

        $data = @{$construct = @{}}

        # foreach($key in $MyInvocation.MyCommand.Parameters.Keys){   
        #     $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        #     if ($value -and ($key -ne "InputObject")){
        #         $data.$construct += @{$key = $value}
        #     }
        #}       
    }

    END {
        
    }
}

# ██       ██████   ██████  ███████ 
# ██      ██    ██ ██       ██      
# ██      ██    ██ ██   ███ ███████ 
# ██      ██    ██ ██    ██      ██ 
# ███████  ██████   ██████  ███████ 
                                  

# ███    ███  ██████  ███    ██ ██ ████████  ██████  ██████  ██ ███    ██  ██████  
# ████  ████ ██    ██ ████   ██ ██    ██    ██    ██ ██   ██ ██ ████   ██ ██       
# ██ ████ ██ ██    ██ ██ ██  ██ ██    ██    ██    ██ ██████  ██ ██ ██  ██ ██   ███ 
# ██  ██  ██ ██    ██ ██  ██ ██ ██    ██    ██    ██ ██   ██ ██ ██  ██ ██ ██    ██ 
# ██      ██  ██████  ██   ████ ██    ██     ██████  ██   ██ ██ ██   ████  ██████  
                                                                                 
                                                                                 
# ████████  ██████   ██████  ██      ███████ 
#    ██    ██    ██ ██    ██ ██      ██      
#    ██    ██    ██ ██    ██ ██      ███████ 
#    ██    ██    ██ ██    ██ ██           ██ 
#    ██     ██████   ██████  ███████ ███████


# ██████  ███████ ██████  ███████  ██████  ███    ██  █████  ███████ 
# ██   ██ ██      ██   ██ ██      ██    ██ ████   ██ ██   ██ ██      
# ██████  █████   ██████  ███████ ██    ██ ██ ██  ██ ███████ ███████ 
# ██      ██      ██   ██      ██ ██    ██ ██  ██ ██ ██   ██      ██ 
# ██      ███████ ██   ██ ███████  ██████  ██   ████ ██   ██ ███████ 
                                                                   
                                                                   

#  █████  ██████  ███    ███ ██ ███    ██ ██ ███████ ████████ ██████   █████  ████████ ██  ██████  ███    ██ 
# ██   ██ ██   ██ ████  ████ ██ ████   ██ ██ ██         ██    ██   ██ ██   ██    ██    ██ ██    ██ ████   ██ 
# ███████ ██   ██ ██ ████ ██ ██ ██ ██  ██ ██ ███████    ██    ██████  ███████    ██    ██ ██    ██ ██ ██  ██ 
# ██   ██ ██   ██ ██  ██  ██ ██ ██  ██ ██ ██      ██    ██    ██   ██ ██   ██    ██    ██ ██    ██ ██  ██ ██ 
# ██   ██ ██████  ██      ██ ██ ██   ████ ██ ███████    ██    ██   ██ ██   ██    ██    ██  ██████  ██   ████


Function Set-MDUser {
    <#
    .Synopsis
       Set Selected User
    .DESCRIPTION
       Updates a Morpheus User
    #>
    [cmdletbinding()]
    Param (
        [Parameter()]
        [String]
        $username,
        [Parameter()]
        [String]
        $firstName,
        [Parameter()]
        [String]
        $lastName,
        [Parameter()]
        [String]
        $displayName,
        [Parameter()]
        [String]
        $email,
        [Parameter()]
        [String]
        $enabled,
        [Parameter()]
        [String]
        $receiveNotifications,
        [Parameter()]
        [String]
        $accountLocked,
        [Parameter()]
        [String]
        $linuxUsername,
        [Parameter()]
        [String]
        $linuxPassword,
        [Parameter()]
        [String]
        $windowsUsername,
        [Parameter()]
        [String]
        $windowsPassword,
        [Parameter()]
        [String]
        $defaultPersona,          
        # # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        $construct = "user"
        $API = "/api/users/"

        $body = @{}
        $data = @{$construct = @{}}
    
    }

    PROCESS {
        $params = $InputObject | Get-Member -MemberType NoteProperty | Where ($_.Definition -like "Object[]*")
        $nestedParams = @()
        foreach($key in $MyInvocation.MyCommand.Parameters.Keys){   
            $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
            if ($value -and ($key -ne "InputObject")){
                $data.$construct += @{$key = $value}
            }
        }
        $body += $data
        $body = $body | ConvertTo-Json -Depth 10
        $put = Invoke-WebRequest -Method PUT -Uri ($URL + $API + $InputObject.ID) -Headers $Header  -Body $body -ErrorVariable err | ConvertFrom-Json
        $put.$Construct
    }

    END {
        
    }
}