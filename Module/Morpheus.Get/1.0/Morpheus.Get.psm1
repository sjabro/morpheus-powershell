#Set Environment Vars
$FormatEnumerationLimit = 8

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
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Administration.Tenants')
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
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Apps')
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
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Operations.Billing')
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
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.BluePrints')
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
        $Name,
        $Group
        )

    Try {

        $API = '/api/zones/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty zone* 

        $Groups = $Group

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Groups $Groups

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Infrastructure.Clouds')
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

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty cypher* 

        #User flag lookup
        $var = Check-Flags -var $var -ItemKey $ItemKey -ID $ID

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Services.Cypher')
            }

        return $var

        }
    Catch {
        Write-Host "Failed to retreive anything from cypher." -ForegroundColor Red
        }
    }

Function Get-MDHistory {  
    Param (
        $Instance,
        $InstanceID,
        $Server,
        $ServerID
        )

    Try {

        $API = '/api/processes/'
        $var = @()

        #Param Lookups
        If ($Server) {
            $ServerID = (Get-MDServer -Name $Server).id
            }
        If ($Instance) {
            $InstanceID = (Get-MDInstance -Name $Instance).id
            }

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty process* 

        #User flag lookup
        $var = Check-Flags -var $var -InstanceID $InstanceID -ServerID $ServerID

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Instances.History')
            }  

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

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty instance*

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Cloud $Cloud -CloudId $CloudId -Group $Group -GroupId $GroupId

        #Give this object a unique typename
        Foreach ($Object in $var) { 
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Instances')
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
        $ID,
        $ProvisionType
        )

    Try {

        $API = '/api/service-plans/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty servicePlan* 
        
        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -ProvisionType $ProvisionType

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Administration.PlansAndPricing.Plan')
            }

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any plans." -ForegroundColor Red
        }
    }

Function Get-MDPolicy {
    Param (
        $ID,
        $Name,
        $PolicyType,
        $Enabled
        )

    Try {
        $API = '/api/policies/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty policies 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Enabled $Enabled -PolicyType $PolicyType

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Administration.Policies')
            }

        return $var
        }
    Catch {
        Write-Host "Failed to retreive any policies." -ForegroundColor Red
        }
    }

Function Get-MDPowerSchedule {
    Param (
        $ID,
        $Name,
        $Enabled
        )
    Try {
        $API = '/api/power-schedules/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty schedule* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Enabled $Enabled

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Operations.Scheduling.PowerSchedule')
            }

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

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty role* 

        #User flag lookup
        $var = Check-Flags -var $var -Authority $Authority -ID $ID -RoleType $RoleType

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Administration.Roles')
            }

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

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty server* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Zone $Cloud -ZoneId $CloudId -OS $OS

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Instances.Servers')
            }
        
        return $var

        }
    Catch {
        Write-Host "Failed to retreive any servers." -ForegroundColor Red
        }
    }

Function Get-MDTask {
    Param (
        $ID,
        $Name,
        $TaskType
        )

        $API = '/api/tasks/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty task* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -TaskType $TaskType
        
        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Automation.Tasks')
            }

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

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty task* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Automation.Tasks.Types')
            }

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any task types." -ForegroundColor Red
        }
    }

Function Get-MDUser {
    Param (
        $Account,
        $AccountID,
        $ID,
        $Username,
        $DisplayName
        )

    Try {

        $var = @()
      
        $Accounts = Get-MDAccount | select -ExpandProperty id

        #User Lookup
        foreach ($a in $accounts) {
            $API = "/api/accounts/$a/users"
            $obj = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
            ConvertFrom-Json | select -ExpandProperty user* 
            $var += $obj
            }
        
        #User flag lookup
        $var = Check-Flags -var $var -Username $Username -ID $ID -AccountID $AccountID -DisplayName $DisplayName -Account $Account
    
        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Administration.Users')
            }

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any users." -ForegroundColor Red
        }
    }

Function Get-MDVirtualImage {
    Param (
        $ID,
        $Name,
        $ImageType,
        $Uploaded
        )

    Try {

        $API = '/api/virtual-images/'
        $var = @()

        #User Lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty virtualImage* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -ImageType $ImageType -Uploaded $Uploaded

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.VirtualImages')
            }

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

        #User Lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | select -ExpandProperty task* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Task $Task

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Automation.Workflow')
            }

        return $var

        }
    Catch {
        Write-Host "Failed to retreive any workflows." -ForegroundColor Red
        }

    }