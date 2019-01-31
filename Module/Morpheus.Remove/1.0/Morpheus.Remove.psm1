<#Function Check-Flags {
    Param (
        $var,
        [AllowEmptyString()]$Account,
        [AllowEmptyString()]$AccountID,
        [AllowEmptyString()]$Active,
        [AllowEmptyString()]$Authority,
        [AllowEmptyString()]$Category,
        [AllowEmptyString()]$Cloud,
        [AllowEmptyString()]$CloudId,
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
        [AllowEmptyString()]$ZoneId
        )    

    If ($Account) {
        $var = $var | Where-Object { $_.account.name -like $Account }
        }

    If ($AccountID){
        $var = $var | where accountid -like $AccountID
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

    If ($Name) {
        $var = $var | where name -like $Name
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

    If ($Username) {
        $var = $var | where username -like $Username
        }

    If ($Zone) {
        $var = $var | Where-Object { $_.zone.name -like $Zone }
        }

    If ($ZoneId) {
        $var = $var | Where-Object { $_.zone.id -like $ZoneId }
        }

    return $var
    }

#>
Function Remove-MDInstance {
    [cmdletbinding(
        SupportsShouldProcess=$True,
        ConfirmImpact = 'High'
        )]

    Param (
        $ID,
        $Name,
        $Cloud,
        $CloudId,
        $Group,
        $GroupId
        )

    Try {

        $API = '/api/instances/'
        $var = @()    

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty instance*

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Cloud $Cloud -CloudId $CloudId -Group $Group -GroupId $GroupId

        #Process request
        Foreach ($v in $var) {
            $N = $v.name
            If ($PSCmdlet.ShouldProcess("$n","Remove Instance")) {
                Invoke-WebRequest -Method Delete -Uri ($URL + $API + $v.id) -Headers $Header
                }
            }
        }
    Catch {
        Write-Host "Failed to retreive any matching instances." -ForegroundColor Red
        }
    }

Function Remove-MDPolicy {
    [cmdletbinding(
        SupportsShouldProcess=$True,
        ConfirmImpact = 'High'
        )]

    Param (
        $ID,
        $Name,
        $PolicyType,
        $Enabled
        )

        Try {
            $Error.Clear()
            $API = '/api/policies/'
            $var = @()

            #API lookup
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
            ConvertFrom-Json | select -ExpandProperty policies 

            #User flag lookup
            $var = Check-Flags -var $var -Name $Name -ID $ID -Enabled $Enabled -PolicyType $PolicyType

            If (!$var) {
                $Error.Count = 1
                }
            #Process request
            Foreach ($v in $var) {
                $N = $v.name
                If ($PSCmdlet.ShouldProcess("$n","Remove Policy")) {
                    Invoke-WebRequest -Method Delete -Uri ($URL + $API + $v.id) -Headers $Header
                    }
                }
            }
        Catch {
            Write-Host "Failed to retreive any matching policies." -ForegroundColor Red
            }
    }