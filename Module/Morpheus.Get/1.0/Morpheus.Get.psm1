#Set Environment Vars
$FormatEnumerationLimit = 8


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
                                                                                

# This section contains functions for getting objects from the Operations primary tab
#
# Current capabilities:
# 1. Billing
# 2. History
#
#  To be completed:

Function Get-MDBilling {
    <#
    .Synopsis
       Billing return per Tenant.
    .DESCRIPTION
       Pricing returned is cost of month to date.  This is filtered per tenant by default.
    #>
    
    Param (
        # Name
        [Parameter(Position=0)]
        [string]
        $Name,
        $AccountID
        )

    Try {

        $API = '/api/billing/account/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'accountId', 'Name', 'Price'

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty bill* 

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

Function Get-MDHistory {  
    <#
    .Synopsis
       History IDs and status from instances
    .DESCRIPTION
       Status of processes run against instance returned as a list of objects
    #>
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
        ConvertFrom-Json | Select-Object  -ExpandProperty process* 

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


# ██████  ██████   ██████  ██    ██ ██ ███████ ██  ██████  ███    ██ ██ ███    ██  ██████  
# ██   ██ ██   ██ ██    ██ ██    ██ ██ ██      ██ ██    ██ ████   ██ ██ ████   ██ ██       
# ██████  ██████  ██    ██ ██    ██ ██ ███████ ██ ██    ██ ██ ██  ██ ██ ██ ██  ██ ██   ███ 
# ██      ██   ██ ██    ██  ██  ██  ██      ██ ██ ██    ██ ██  ██ ██ ██ ██  ██ ██ ██    ██ 
# ██      ██   ██  ██████    ████   ██ ███████ ██  ██████  ██   ████ ██ ██   ████  ██████  

# This section contains functions for getting objects from the Provisioning primary tab
#
# CURRENT CAPABILITIES:
# 1. Instances: Get-MDInstance
# 2. Apps
# 3. Blueprints
# 4. Automation: Tasks
# 5. Automation: Task Types
# 6. Automation: Workflows
# 7. Automation: Power Schedules
# 8. Virtual Images
#
# TO BE COMPLETED:
# 1. Library: Instance Types
# 2. Library: Layouts
# 3. Library: Node Types
# 4. Library: Option Types
# 5. Library: Option Lists
# 6. Library: File Templates
# 7. Library: Scripts
# 8. Library: Spec Templates
# 9. Library: Cluster Layouts

Function Get-MDInstance {
    <#
    .Synopsis
       Get all instances from Morpheus appliance
    .DESCRIPTION
       Gets all instances based on the switch selection of Name,ID, Cloud Name, Cloud ID, Group Name or Group ID. 
       Name can be used from position 0 without the switch to get a specific instance by name.
       Can accept pipeline input from the Get-MDCloud and Get-MDGroup functions
    .EXAMPLE
        Get-MDInstance -Name instance1
        
        This will return the data for an instance named "instance1"
    .EXAMPLE
        Get-MDInstance instance1

        This will return the data for an instance named "instance1"
    .EXAMPLE
        Get-MDInstance -Cloud cloud1

        This will return all instances related to the Cloud "cloud1"
    .EXAMPLE
        Get-MDCloud "cloud1" | Get-MDInstance

        This will get the object ofthe cloud "cloud1" and pipe that object to Get-MDInstance. This will return all instances for the cloud.
    .EXAMPLE
        Get-MDGroup "Developers" | Get-MDInstance

        This will get the object of the group "developers" and pipe that object to Get-MDInstance. This will return all instances for the group.
    #>
    [cmdletbinding()]
    Param (
        # Name of the Instance
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [int]
        $ID,
        # Name of the cloud
        [Parameter()]
        [string]
        $Cloud,
        # ID of the cloud
        [Parameter()]
        [int]
        $CloudId,
        [Parameter()]
        [string]
        $Group,
        [Parameter()]
        [int]
        $GroupId,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [object]
        $InputObject
        )
        
        process {

            # Set parameters for flag check via pipeline
            if ($InputObject.zoneType){
                $Cloud = $InputObject.Name
                $CloudId = $InputObject.Id
            }else{
                $Group = $InputObject.name
                $GroupID = $InputObject.Id
            }

            Try {

                $API = '/api/instances/'
                $var = @()    

                #API lookup
                $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
                ConvertFrom-Json | Select-Object  -ExpandProperty instance*

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
        }

Function Get-MDApp {
    <#
    .Synopsis
       Get all apps from Morpheus appliance
    .DESCRIPTION
       Gets all apps based on the switch selection of Name, ID, Type, Group Name or Group ID. 
       Name can be used from position 0 without the switch to get a specific app by name.
       Can accept pipeline input from the Get-MDGroup function
    .EXAMPLE
        Get-MDApp -Name app1
        
        This will return the data for an app named "app1"
    .EXAMPLE
        Get-MDApp app1

        This will return the data for an app named "app1"
    .EXAMPLE
        Get-MDApp -Group "developers"

        This will return all apps related to the group "developers"
    .EXAMPLE
        Get-MDGroup "developers" | Get-MDInstance

        This will get the object of the group "developers" and pipe that object to Get-MDApp. This will return all apps for the group.
    #>
    [cmdletbinding()]
    Param (
        # Name of the app
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [int]
        $ID,
        [Parameter()]
        [string]
        $Type,
        [Parameter()]
        [string]
        $Group,
        [Parameter()]
        [int]
        $GroupId,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [object]
        $InputObject
        )

    process {

        # Set parameters for flag check via pipeline
        $Group = $InputObject.name
        $GroupID = $InputObject.Id

        Try {

            $API = '/api/apps/'
            $var = @()
            
            #API lookup
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
            ConvertFrom-Json | Select-Object  -ExpandProperty app* 

            #User flag lookup
            $var = Check-Flags -var $var -Name $Name -ID $ID -Type $Type -Group $Group -GroupId $GroupId

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
    }                                                                                 

Function Get-MDBlueprint {
    <#
    .Synopsis
       Get all blueprints from Morpheus appliance
    .DESCRIPTION
       Gets all blueprints based on the switch selection of Name, ID, Category or Type. 
       Name can be used from position 0 without the switch to get a specific blueprint by name.
    .EXAMPLE
        Get-MDBlueprint -Name bp1
        
        This will return the data for an app named "bp1"
    .EXAMPLE
        Get-MDBlueprint bp1

        This will return the data for an app named "bp1"
    .EXAMPLE
        Get-MDBlueprint -Category "morpheus"

        This will return all blueprints of the category "morpheus"
    #>
    [cmdletbinding()]
    Param (
        # Name of the blueprint
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $Category,
        $Type
        )

    Try {

        $API = '/api/blueprints/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty blueprints 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Category $Category -Type $Type

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

# AUTOMATION

Function Get-MDTask {
    <#
    .Synopsis
       Get all tasks from Morpheus appliance
    .DESCRIPTION
       Gets all or one task based on the switch selection of Name, ID, TaskType. 
       Name can be used from position 0 without the switch to get a specific task by name.
    .EXAMPLE
        Get-MDTask -Name task1
        
        This will return the data for a task named "task1"
    .EXAMPLE
        Get-MDTask task1
        
        This will return the data for a task named "task1"
    .EXAMPLE
        Get-MDTask -TaskType "Ansible Playbook"

        This will return all tasks of the task type "Ansible Playbook"
    #>
    [cmdletbinding()]
    Param (
        # Name of the Task
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $TaskType
        )

        $API = '/api/tasks/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty task* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -TaskType $TaskType
        
        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Automation.Tasks')
            }

    return $var

    }

Function Get-MDPowerSchedule {
    Param (
        # Name of the Power Schedule
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $Enabled
        )
    Try {
        $API = '/api/power-schedules/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty schedule* 

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

Function Get-MDTaskType {
    Param (
        # Name of the Task Type
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID
        )

    Try {

        $API = '/api/task-types/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty task* 

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

Function Get-MDWorkflow {
    Param (
        # Name of the Workflow
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $Task
        )
    
    Try {
    
        $API = '/api/task-sets/'
        $var = @()

        #User Lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object   -ExpandProperty task* 

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

Function Get-MDVirtualImage {
    Param (
        # Name of the Virtual Image
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $ImageType,
        $Uploaded
        )

    Try {

        $API = '/api/virtual-images/'
        $var = @()

        #User Lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object   -ExpandProperty virtualImage* 

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


# ██ ███    ██ ███████ ██████   █████  ███████ ████████ ██████  ██    ██  ██████ ████████ ██    ██ ██████  ███████ 
# ██ ████   ██ ██      ██   ██ ██   ██ ██         ██    ██   ██ ██    ██ ██         ██    ██    ██ ██   ██ ██      
# ██ ██ ██  ██ █████   ██████  ███████ ███████    ██    ██████  ██    ██ ██         ██    ██    ██ ██████  █████   
# ██ ██  ██ ██ ██      ██   ██ ██   ██      ██    ██    ██   ██ ██    ██ ██         ██    ██    ██ ██   ██ ██      
# ██ ██   ████ ██      ██   ██ ██   ██ ███████    ██    ██   ██  ██████   ██████    ██     ██████  ██   ██ ███████ 

Function Get-MDCloud {
    [cmdletbinding()]
    Param (
        # Name of the Cloud
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $Group
        )

    Try {

        $API = '/api/zones/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty zone* 

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

Function Get-MDServer {
    Param (
        # Name of the Server
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $Cloud,
        $CloudId,
        $OS
        )

    Try {

        $API = '/api/servers/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty server* 

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

Function Get-MDNetwork {
    Param (
        # Name of the network
        [Parameter(Position=0)]
        [string]
        $Name
        )

    Try {

        $API = '/api/networks/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object   -ExpandProperty Networks* 

        $Groups = $Group

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Cloud $Cloud

        #Give this object a unique typename
        Foreach ($Object in $var) {
            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Infrastructure.Networks')
            }

        return $var
        }
    Catch {
        Write-Host "Failed to retreive any networks." -ForegroundColor Red
        }

    }

    Function Get-MDGroup {
        Param (
            # Name of the Group
            [Parameter(Position=0)]
            [string]
            $Name
            )
    
        Try {
    
            $API = '/api/groups/'
            $var = @()
    
            #API lookup
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
            ConvertFrom-Json | select-object -ExpandProperty Groups* 
    
            $Groups = $Group
    
            #User flag lookup
            $var = Check-Flags -var $var -Name $Name
    
            #Give this object a unique typename
            Foreach ($Object in $var) {
                $Object.PSObject.TypeNames.Insert(0,'Morpheus.Infrastructure.Groups')
                }
    
            return $var
            }
        Catch {
            Write-Host "Failed to retreive any networks." -ForegroundColor Red
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
        ConvertFrom-Json | Select-Object  -ExpandProperty cypher* 

        #User flag lookup
        $var = Check-Flags -var $var -ItemKey $ItemKey -ID $ID -NameLike $NameLike 

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
                                                                                                           
                                                                                                           
Function Get-MDAccount {
    Param (
        # Name of the account
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $Currency,
        $Active
        )

    Try {

        $API = '/api/accounts/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object -ExpandProperty account* 

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


Function Get-MDPlan {
    Param (
        # Name of the Plan
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $ProvisionType
        )

    Try {

        $API = '/api/service-plans/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty servicePlan* 
        
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
        # Name of the Policy
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $PolicyType,
        $Enabled
        )

    Try {
        $API = '/api/policies/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty policies 

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
        ConvertFrom-Json | Select-Object  -ExpandProperty role* 

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


Function Get-MDUser {
    Param (
        # Name of the Task
        [Parameter(Position=0)]
        [string]
        $Username,
        $Account,
        $AccountID,
        $ID,
        $DisplayName
        )

    Try {

        $var = @()
      
        $Accounts = Get-MDAccount | Select-Object  -ExpandProperty id

        #User Lookup
        foreach ($a in $accounts) {
            $API = "/api/accounts/$a/users"
            $obj = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
            ConvertFrom-Json | Select-Object   -ExpandProperty user* 
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
