Function Compare-Flags {
    Param (
        $var,
        [AllowEmptyString()]$Name,
        [AllowEmptyString()]$Username,
        #Parameter help description
        [Parameter()]
        [Object]
        $InputObject,
        # Parameter help description
        [Parameter()]
        [String]
        $Construct,
        # Parameter help description
        [Parameter()]
        [string]
        $PipelineConstruct

        )    

    #Write-Host "BEGIN: Compare-Flags" -ForegroundColor DarkGreen
    #Write-Host "Var: $($var)" -ForegroundColor DarkMagenta
    if ($Construct.Contains("-")){
        #Write-Host "Found a dash. Killing it!"
        $Construct = $Construct -replace '[-]'
        #Write-Host "New construct: $($Construct)"
    }

    $var = $var.$construct


    $return =@()

    #Write-Host "Input Object: $($InputObject)" -ForegroundColor DarkMagenta
    #Write-Host "Construct: $($construct)" -ForegroundColor DarkMagenta
    #Write-Host "Pipeline Construct: $($PipelineConstruct)" -ForegroundColor DarkMagenta
    #Write-Host $var  -ForegroundColor DarkMagenta

    if ($PipelineConstruct -ne $Construct){
        #Write-Host "Found pipeline construct: $($PipelineConstruct)"  -ForegroundColor DarkMagenta
        # This switch checks for the initial command in the pipeline          
        switch ($PipelineConstruct){
            accounts {
                # This switch checks for the current construct to compare against and the parse the var based on the object layout
                switch ($construct){
                    { ($_ -eq "invoices") } {
                        $var = $var | Where-Object { $_.account.id -Like $InputObject.id }
                    }
                    default {
                        $var = $var | where accountId -Like $InputObject.id
                    }
                }
            }
            users {
                switch ($construct){
                    roles {
                        $return = @()
                        foreach ($item in $InputObject.roles){
                            foreach ($obj in $var){
                                if ($obj.id -like $item.id){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    { ($_ -eq "invoices") } {
                        $var = $var | Where-Object { $_.user.id -Like $InputObject.id }
                    }
                    { ($_ -eq "instances" -or $_ -eq "apps" -or $_ -eq "blueprints" -or $_ -eq "servers") } {
                        $var = $var | Where-Object { $_.owner.id -Like $InputObject.id }
                    }
                    default {
                        $var = $var | where id -Like $InputObject.id
                    }          
                }
            }
            groups {
                switch ($construct){
                    clusters {
                        $var = $var | Where-Object { $_.site.id -like $InputObject.id }
                    }
                    { ($_ -eq "instances" -or $_ -eq "apps" -or $_ -eq "invoices") } {
                        $var = $var | Where-Object { $_.group.id -Like $InputObject.id }
                    }
                    default {
                        $var = $var | Where-Object { $_.groups.id -Like $InputObject.id }
                    }          
                }             
            }
            clouds {
                switch ($construct){
                    groups {
                        $return = @()
                        foreach ($item in $InputObject.groups){
                            foreach ($obj in $var){
                                if ($obj.id -like $item.id){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    { ($_ -eq "instances" -or $_ -eq "invoices") } {
                        $var = $var | Where-Object { $_.cloud.id -Like $InputObject.id }
                    }
                    default {
                        $var = $var | Where-Object { $_.zone.id -Like $InputObject.id }
                    }   
                }
            }
            clusters {
                switch ($construct){
                    servers {
                        $return = @()
                        foreach ($item in $InputObject.Servers){
                            foreach ($obj in $var){
                                if ($obj.id -like $item.id){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    default {
                        $var = $var | Where-Object { $_.groups.id -Like $InputObject.id }
                    }   
                }
            }
            networks {
                switch ($construct){
                    networkpools {
                        $return = @()
                        foreach ($item in $InputObject.pool){
                            foreach ($obj in $var){
                                if ($obj.id -like $item.id){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    networkdomains {
                        $return = @()
                        foreach ($item in $InputObject.networkDomain){
                            foreach ($obj in $var){
                                if ($obj.id -like $item.id){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    default {
                        $var = $var | Where-Object { $_.groups.id -Like $InputObject.id }
                    }   
                }
            }
            instances {
                switch ($construct){
                    networks {
                        foreach ($item in $InputObject.interfaces){
                            foreach ($obj in $var){
                                if ($obj.id -like $item.network.id){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    servers {
                        foreach ($item in $InputObject.servers){
                            foreach ($obj in $var){
                                if ($obj.id -like $item){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    default {
                        $var = $var | where id -Like $InputObject.id
                    }          
                }
            }
            apps {
                switch ($construct){
                    instances {
                        $return = @()
                        foreach ($item in $InputObject.appTiers.appInstances.Instance){
                            foreach ($obj in $var){
                                if ($obj.id -like $item.id){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    default {
                        $var = $var | Where-Object { $_.zone.id -Like $InputObject.id }
                    }   
                }
            }
            #Workflows
            taskSets {
                switch ($construct){
                    tasks {
                        $return = @()
                        foreach ($item in $InputObject.tasks){
                            foreach ($obj in $var){
                                #Write-Host "Checking object: $obj" -ForegroundColor DarkBlue
                                #Write-Host "Checking item: $item" -ForegroundColor Blue
                                if ($obj.id -like $item){
                                    $return += $obj
                                }
                            }
                        }
                        $var = $return
                    }
                    # default {
                    #     $var = $var | Where-Object { $_.zone.id -Like $InputObject.id }
                    # }   
                }
            }
            instanceTypes {
                switch ($construct){
                    default {
                        $var = $var | Where-Object { $_.instanceType.id -Like $InputObject.id }
                    }   
                }
            }
        }
    }else{
        #Write-Host "Pipeline: $($PipelineConstruct) is the same as Construct:$($Construct)" -ForegroundColor DarkMagenta
    }

    If ($Username) {
        #Write-Host "Found by username"
        $var = $var | where username -like $Username
        }

    If ($Name) {
        #Write-Host "Found by name"
        $var = $var | Where-Object name -like $Name
        }

    #Write-Host "Var: $($var)" -ForegroundColor DarkMagenta
    #Write-Host "END: Compare-Flags" -ForegroundColor DarkGreen
    return $var
}


# Function to parse the input from the pipeline 
function Get-PipelineConstruct {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $PipelineConstruct
    )

    $SplitString = "-md"
    $PipelineConstruct = $PipelineConstruct.Split($SplitString)[1]
    $PipelineConstruct = $PipelineConstruct.Split(" ")[0]
    $PipelineConstruct = $PipelineConstruct.ToLower() + "s"

    return $PipelineConstruct
}

# function Get-AttributesList {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory=$true)]
#         [string]
#         $API,
#         [Parameter(Mandatory=$false)]
#         [Switch]
#         $IgnoreCommonAttributes
#     )

#     $commonAttributes = "id","name"

#     switch ($API) {
#         user {
#             $attributes = "id","username","firstname","lastname"
#             if ($IgnoreCommonAttributes -eq $true){
#                 $attributesList = $attributes
#             }else{
#                 $attributesList = $commonAttributes + $attributes
#             }
#         }
#         Default {}
#     }
#     return $attributesList
# }

# Export-ModuleMember -Function Get-AttributesList
# Export-ModuleMember -Variable attributesList
Export-ModuleMember -Function Get-PipelineConstruct
Export-ModuleMember -Variable PipelineConstruct
Export-ModuleMember -Variable Var
Export-ModuleMember -Function Compare-Flags