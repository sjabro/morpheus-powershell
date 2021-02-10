Function Check-Flags {
    Param (
        $var,
        [AllowEmptyString()]$Account,
        [AllowEmptyString()]$AccountID,
        [AllowEmptyString()]$TenantID,
        [AllowEmptyString()]$Active,
        [AllowEmptyString()]$Authority,
        [AllowEmptyString()]$Category,
        [AllowEmptyString()]$Cloud,
        [AllowEmptyString()]$CloudId,
        [AllowEmptyString()]$CloudType,
        [AllowEmptyString()]$ClusterType,
        [AllowEmptyString()]$ClusterId,
        [AllowEmptyString()]$Currency,
        [AllowEmptyString()]$DisplayName,
        [AllowEmptyString()]$Enabled,
        [AllowEmptyString()]$Group,
        [AllowEmptyString()]$GroupId,
        [AllowEmptyString()]$ID,
        [AllowEmptyString()]$ItemKey,
        [AllowEmptyString()]$ImageType,
        [AllowEmptyString()]$InstanceID,
        [AllowEmptyString()]$Name,
        [AllowEmptyString()]$PolicyType,
        [AllowEmptyString()]$ProvisionType,
        [AllowEmptyString()]$RoleType,
        [AllowEmptyString()]$ServerID,
        [AllowEmptyString()]$Task,
        [AllowEmptyString()]$TaskType,
        [AllowEmptyString()]$Uploaded,
        [AllowEmptyString()]$Username,
        [AllowEmptyString()]$Zone,
        [AllowEmptyString()]$ZoneId,
        [AllowEmptyString()]$Type,
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

    #Write-Host "Begin check-flags"
    if ($PipelineConstruct -eq "usersOnly"){
        $var = $var
    }else{
        $var = $var.$construct
    }

    $return =@()

    #Write-Host "Input Object: $($InputObject)" -ForegroundColor DarkMagenta
    #Write-Host "Construct: $($construct)" -ForegroundColor DarkMagenta
    #Write-Host "Pipeline Construct: $($PipelineConstruct)" -ForegroundColor DarkMagenta
    #Write-Host $var  -ForegroundColor DarkMagenta

    if ($PipelineConstruct){
        #Write-Host "Found pipeline construct: $($PipelineConstruct)"  -ForegroundColor DarkMagenta
        # This switch checks for the initial command in the pipeline          
        switch ($PipelineConstruct){
            accounts {
                # This switch checks for the current construct to compare against and the parse the var based on the object layout
                switch ($construct){
                    default {
                        $var = $var | where accountId -Like $InputObject.id
                    }
                }
            }
            users {
                switch ($construct){
                    default {
                        $var = $var | where id -Like $InputObject.id
                    }          
                }
            }
            groups {
                switch ($construct){
                    instances {
                        $var = $var | Where-Object { $_.group.id -Like $InputObject.id }
                    }
                    default {
                        $var = $var | Where-Object { $_.groups.id -Like $InputObject.id }
                    }          
                }             
            }
            zones {
                switch ($construct){
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
        }
    }

    If ($Username) {
        #Write-Host "Found by username"
        $var = $var | where username -like $Username
        }

    If ($Name) {
        #Write-Host "Found by name"
        $var = $var | Where-Object name -like $Name
        }

    If ($Active){
        $var = $var | where accountid -like $Active
        }

    If ($Authority){
        $var = $var | where authority -like $Authority
        }

    If ($Category){
        $var = $var | where category -like $Category
        }

    If ($Cloud) {
        $var = $var | Where-Object { $_.Cloud.name -like $Cloud }
        }

    If ($CloudId) {
        $var = $var | Where-Object { $_.Cloud.id -like $CloudId }
        }

    If ($Currency){
        $var = $var | where currency -like $Currency
        }

    If ($Enabled){
        $var = $var | where enabled -like $Enabled
        }

    If ($Group) {
        $var = $var | Where-Object { $_.Group.name -like $Group }
        }

    If ($GroupId) {
        $var = $var | Where-Object { $_.Group.id -like $GroupId }
        }

    If ($Groups) {
        $var = $var | Where-Object { $_.groups.name -like $Groups }
        }

    If ($DisplayName){
        $var = $var | where displayName -like $DisplayName
        }

    If ($ID) {
        $var = $var | where id -like $ID
        }

    If ($ItemKey) {
        $var = $var | where itemKey -like $ItemKey
        }

    If ($ImageType) {
        $var = $var | where imageType -like $ImageType
        }

    If ($InstanceID) {
        $var = $var | where instanceId -like $InstanceID
        }

    If ($OS) {
        $var = $var | Where-Object { $_.serverOs.name -like $OS }
        }

    If ($PolicyType) {
        $var = $var | Where-Object { $_.policyType.name -like $PolicyType }
        }

    If ($ProvisionType) {
        $var = $var | Where-Object { $_.provisionType.code -like $ProvisionType }
        }
    
    If ($RoleType) {
        $var = $var | where roleType -like $RoleType
        }

    If ($ServerID) {
        $var = $var | where serverId -like $ServerID
        }

    If ($Task) {
        $var = $var | where tasks -like $Task
        }

    If ($TaskType) {
        $var = $var | Where-Object { $_.taskType.name -like $TaskType }
        }

    If ($Uploaded) {
        $var = $var | where userUploaded -like $Uploaded
        }

    If ($Zone) {
        $var = $var | Where-Object { $_.zone.name -like $Zone }
        }

    If ($ZoneId) {
        $var = $var | Where-Object { $_.zone.id -like $ZoneId }
        }
    
    If ($CloudType) {
        $var = $var | Where-Object { $_.zoneType.name -like $CloudType }
        }

    If ($ClusterType) {
        $var = $var | Where-Object { $_.Type.name -like $ClusterType }
        }

    If ($ClusterId) {
        $var = $var | where clusterId -like $ClusterId
        }

    If ($Type) {
        $var = $var | Where-Object type -like $Type
        }
    
    #Write-Host "End check-flags"
    return $var
}

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

Export-ModuleMember -Function Get-PipelineConstruct
Export-ModuleMember -Variable PipelineConstruct
Export-ModuleMember -Variable Var
Export-ModuleMember -Function Check-Flags