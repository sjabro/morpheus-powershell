$FormatEnumerationLimit = 8
Update-FormatData -AppendPath C:\Users\Bunge\OneDrive\Document\GitHub\morpheus-powershell\Module\Working\Morpheus.Format.ps1xml

<#   NOTES  
  --[cmdletbinding(SupportsShouldProcess=$True)] adds '-WhatIf' functionality to items
  --Come Back to Billing Logic
#>

Function Check-Flags {
    Param (
        $var,
        [AllowEmptyString()]$AccountID,
        [AllowEmptyString()]$Active,
        [AllowEmptyString()]$Authority,
        [AllowEmptyString()]$Category,
        [AllowEmptyString()]$Cloud,
        [AllowEmptyString()]$CloudId,
        [AllowEmptyString()]$Currency,
        [AllowEmptyString()]$DisplayName,
        [AllowEmptyString()]$Group,
        [AllowEmptyString()]$GroupId,
        [AllowEmptyString()]$ID,
        [AllowEmptyString()]$ItemKey,
        [AllowEmptyString()]$InstanceID,
        [AllowEmptyString()]$Name,
        [AllowEmptyString()]$RoleType,
        [AllowEmptyString()]$Task,
        [AllowEmptyString()]$Username,
        [AllowEmptyString()]$Zone,
        [AllowEmptyString()]$ZoneId
        )    

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

    If ($Group) {
        $var = $var | Where-Object { $_.Group.name -like $Group }
        }

    If ($GroupId) {
        $var = $var | Where-Object { $_.Group.id -like $GroupId }
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

    If ($InstanceID) {
        $var = $var | where instanceId -like $InstanceID
        }

    If ($Name) {
        $var = $var | where name -like $Name
        }

    If ($OS) {
        $var = $var | Where-Object { $_.serverOs.name -like $OS }
        }
    
    If ($RoleType) {
        $var = $var | where roleType -like $RoleType
        }

    If ($Task) {
        $var = $var | where tasks -like $Task
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
        $Script:URL = ('https://' + $URL)
        }
        ELSE {
        $Script:URL = $URL
        }
    if (-not($Password)) {
        $Password = Read-host 'Enter Password' -AsSecureString
        $PlainTextPassword= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( ($Password) ))
        }
    ELSE {
        $PlainTextPassword = $Password
        }

    Try {
        $Error.Clear()
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
        Write-Host "Failed to authenticate credentials" -ForegroundColor Red
        }
    Finally {
        if ($Error.Count -le 0) {
            Write-Host "Successfully connected to $URL
Use `"Get-Command -Module Morpheus`" to discover available commands." -ForegroundColor Yellow
            }
        }    
    }

Function Get-MDAccount {
    Param (
        $ID,
        $Name,
        $Currency,
        $Active
        )

    Try {

        $API = '/api/accounts/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty account* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Currency $Currency -Active $Active

        #Give this object a unique typename
        Foreach ($Object in $var) { 
        $Object.PSObject.TypeNames.Insert(0,'Morpheus.Account.Information')
            }
        
        $Account = $var

        return $Account

        }
    Catch {
        Write-Host "Failed to retreive any accounts." -ForegroundColor Red
        }

    }

Function Get-MDApp {
    Param (
        $ID,
        $Name
        )

    Try {

        $API = '/api/apps/'
        $var = @()
        
        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty app* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID

        #Give this object a unique typename
        Foreach ($Object in $var) {
        $Object.PSObject.TypeNames.Insert(0,'Morpheus.Instance.Application')
            }

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any apps." -ForegroundColor Red
        }

    }

Function Get-MDBilling {
    <#
    .Synopsis
       Billing return per Tenant.
    .DESCRIPTION
       Pricing returned is cost of month to date.  This is filtered per tenant by default.
    #>
    
    Param (
        $AccountID,
        $Name
        )

    Try {

        $API = '/api/billing/account/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'accountId', 'Name', 'Price'

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty bill* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -AccountID $AccountID

        #Give this object a unique typename
        Foreach ($Object in $var) {
        $Object.PSObject.TypeNames.Insert(0,'Morpheus.Account.Billing')
            }

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any billing." -ForegroundColor Red
        }

    }

Function Get-MDBlueprint {
    Param (
        $ID,
        $Name,
        $Category
        )

    Try {

        $API = '/api/app-templates/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty appTemplates 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Category $Category

        #Give this object a unique typename
        Foreach ($Object in $var) {
        $Object.PSObject.TypeNames.Insert(0,'Morpheus.Instance.Blueprint')
            }

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any blueprints." -ForegroundColor Red
        }
    }

Function Get-MDBuild {
    Param (
        )

        $API = '/api/setup/check/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json

    return $var

    }

Function Get-MDCloud {
    Param (
        $ID,
        $Name
        )

    Try {

        $API = '/api/zones/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty zone* 

        $var = Check-Flags -var $var -Name $Name -ID $ID

        #Give this object a unique typename
        Foreach ($Object in $var) {
        $Object.PSObject.TypeNames.Insert(0,'Morpheus.Infrastructure.Cloud')
            }

        return $var
        }
    Catch {
        Write-Host "Failed to retreive any clouds." -ForegroundColor Red
        }

    }

Function Get-MDCypher {
    Param (
        $ID,
        $ItemKey
        )

    Try {

        $API = '/api/cypher/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'itemKey', 'expireDate'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty cypher* 

        $var = Check-Flags -var $var -ItemKey $ItemKey -ID $ID

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var

        }
    Catch {
        Write-Host "Failed to retreive anything from cypher." -ForegroundColor Red
        }
    }

Function Get-MDHistory {  
    Param (
        $InstanceID
        )

    Try {

        $API = '/api/processes/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'instanceId', 'processType', 'status'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty process* 

        $var = Check-Flags -var $var -InstanceID $InstanceID

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any history." -ForegroundColor Red
        }

    }

Function Get-MDInstance {
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

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty instance*

        $var = Check-Flags -var $var -Name $Name -ID $ID -Cloud $Cloud -CloudId $CloudId -Group $Group -GroupId $GroupId

        Foreach ($Object in $var) { 
        $Object.PSObject.TypeNames.Insert(0,'Morpheus.Instance.Information')
            }

        return $var
        }
    
    Catch {
        Write-Host "Failed to retreive any instances." -ForegroundColor Red
        }
    }

Function Get-MDPlan {
    Param (
        $Name,
        $ID
        )

    Try {

        $API = '/api/service-plans/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'Name', 'provisionType'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty servicePlan* 

        $var = Check-Flags -var $var -Name $Name -ID $ID

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any plans." -ForegroundColor Red
        }
    }

Function Get-MDPolicy {
    Param (
        $ID,
        $Name
        )

    Try {
        $API = '/api/policies/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'Name', 'policyType'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty policies 

        $var = Check-Flags -var $var -Name $Name -ID $ID

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var
        }
    Catch {
        Write-Host "Failed to retreive any policies." -ForegroundColor Red
        }
    }

Function Get-MDPowerSchedule {
    Param (
        $ID,
        $Name
        )
    Try {
        $API = '/api/power-schedules/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'Name', 'enabled', 'totalMonthlyHoursSaved'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty schedule* 

        $var = Check-Flags -var $var -Name $Name -ID $ID

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var
        }
    Catch {
        Write-Host "Failed to retreive any power schedules." -ForegroundColor Red
        }
    }

Function Get-MDRole {
    Param (
        $ID,
        $Authority,
        $RoleType
        )

    Try {

        $API = '/api/roles/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'authority', 'roleType'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty role* 

        $var = Check-Flags -var $var -Authority $Authority -ID $ID -RoleType $RoleType

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any roles." -ForegroundColor Red
        }
    }

Function Get-MDServer {
    Param (
        $ID,
        $Name,
        $Cloud,
        $CloudId,
        $OS
        )

    Try {

        $API = '/api/servers/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'Name', 'internalIp', 'plan', 'sshUsername'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty server* 

        $var = Check-Flags -var $var -Name $Name -ID $ID -Zone $Cloud -ZoneId $CloudId -OS $OS

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        
        return $var

        }
    Catch {
        Write-Host "Failed to retreive any servers." -ForegroundColor Red
        }
    }

Function Get-MDTask {
    Param (
        $ID,
        $Name
        )

    $API = '/api/tasks/'
    $var = @()

    #Configure a default display set
    $defaultDisplaySet = 'ID', 'Name', 'taskType'

    #Create the default property display set
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

    $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
    ConvertFrom-Json | select -ExpandProperty task* 

    $var = Check-Flags -var $var -Name $Name -ID $ID

    #Give this object a unique typename
    $var.PSObject.TypeNames.Insert(0,'Instance.Information')
    $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

    return $var

    }

Function Get-MDTaskType {
    Param (
        $ID,
        $Name
        )

    Try {

        $API = '/api/task-types/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'Name', 'code'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty task* 

        $var = Check-Flags -var $var -Name $Name -ID $ID

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any task types." -ForegroundColor Red
        }
    }

Function Get-MDUser {
    Param (
        $AccountID,
        $ID,
        $Username,
        $DisplayName
        )

    Try {

        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'id', 'accountId', 'displayName', 'username'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $Accounts = Get-Account | select -ExpandProperty id

        foreach ($account in $accounts) {
            $API = "/api/accounts/$Account/users"
            $obj = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
            ConvertFrom-Json | select -ExpandProperty user* 
            $var += $obj
            }

        $var = Check-Flags -var $var -Username $Username -ID $ID -AccountID $AccountID -DisplayName $DisplayName
    
        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Morpheus.Accounts.Users')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any users." -ForegroundColor Red
        }
    }

Function Get-MDVirtualImage {
    Param (
        $ID,
        $Name
        )

    Try {

        $API = '/api/virtual-images/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'Name', 'imageType'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty virtualImage* 

        $var = Check-Flags -var $var -Name $Name -ID $ID

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any virtual images." -ForegroundColor Red
        }

    }

Function Get-MDWorkflow {
    Param (
        $ID,
        $Name,
        $Task
        )
    
    Try {

        $API = '/api/task-sets/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'ID', 'Name', 'tasks', 'lastUpdated'

        #Create the default property display set
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty task* 

        $var = Check-Flags -var $var -Name $Name -ID $ID -Task $Task

        #Give this object a unique typename
        $var.PSObject.TypeNames.Insert(0,'Instance.Information')
        $var | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any workflows." -ForegroundColor Red
        }

    }