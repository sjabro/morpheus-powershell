﻿#Set Environment Vars
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
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [object]
        $InputObject
        )

    Try {

        $API = '/api/billing/account/'
        $var = @()

        #Configure a default display set
        $defaultDisplaySet = 'accountId', 'Name', 'Price'

        #API lookup
        Write-Progress -Activity "Collecting" -Status 'In Progress...'
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API  + "?max=10000") -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty bill* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -InputObject $InputObject

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
        Write-Progress -Activity "Collecting" -Status 'In Progress...'
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
# 1. Instances:                     Get-MDInstance
# 2. Apps:                          Get-MDApp
# 3. Blueprints:                    Get-MDBlueprint
# 4. Automation - Tasks:            Get-MDTask
# 5. Automation - Task Types:       Get-MDTaskTypes
# 6. Automation - Workflows:        Get-MDWorkflows
# 7. Automation - Power Schedules:  Get-MDPowerSchedule
# 8. Virtual Images:                Get-MDVirtualImages
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
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Provisioning"
        $subZone = ""
        $construct = "Instances"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"
    
        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}

Function Get-MDServer {
    <#
    .Synopsis
       Get all servers from Morpheus appliance
    .DESCRIPTION
       Gets all or one servers based on the switch selection of Name, ID
       Name can be used from position 0 without the switch to get a specific server by name.
       Can accept pipeline input from the Get-MDGroup and Get-MDCloud functions

    .EXAMPLE
        Get-MDServer
        
        This will return the data for all servers
    .EXAMPLE
        Get-MDServer server1
        
        This will return the data for a server named "server1"

    .EXAMPLE
    Get-MDGroup "Developers" | Get-MDServer

    This will get the object of the group "developers" and pipe that object to Get-MDCloud. This will return all clouds for the group.

    .EXAMPLE
    Get-MDGroup "Developers" | Get-MDCloud -CloudType "Amazon"

    This will get the object of the group "developers" and pipe that object to Get-MDCloud. This will return all clouds of type "Amazon" for the group.

    #>
    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Provisioning"
        $subZone = "Instances"
        $construct = "Servers"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"
    
        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            $API = "/api/$($construct.ToLower())/"
            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -InputObject $InputObject -Construct $construct.ToLower() -PipelineConstruct $PipelineConstruct
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }           

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
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
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
        Write-Progress -Activity "Collecting" -Status 'In Progress...'
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
       Available task types:
        - Ansible Playbook
        - Ansible Tower Job
        - Chef bootstrap
        - Email
        - Groovy Script
        - HTTP
        - Javascript
        - jRuby Script
        - Library Script
        - Library Template
        - PowerShell Script
        - Puppet Agent Install
        - Python Script
        - Restart
        - Shell Script
        - vRealize Orchestrator Workflow
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
        $TaskType,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [object]
        $InputObject
        )

        process {

        # Set parameters for flag check via pipeline

                $API = '/api/tasks/'
                $return = @()
                $var = @()
                $count = 0
                $itemCount = ($InputObject.tasks).count
                if ($InputObject){
                    foreach ($task in $InputObject.tasks){
                        $ID = $task
                        $count = $count + 1
                        Write-Progress -Activity "Collecting..." -Status 'Progress->' -PercentComplete ($count/$itemCount*100)
                        #API lookup
                        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
                        ConvertFrom-Json | Select-Object  -ExpandProperty task* 

                        #User flag lookup
                        $var = Check-Flags -var $var -Name $Name -ID $ID -TaskType $TaskType
                        
                        #Give this object a unique typename
                        Foreach ($Object in $var) {
                            $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Automation.Tasks')
                            $return += $Object
                            }
                        }
                    return $return
                }else{
                    #API lookup
                    Write-Progress -Activity "Collecting" -Status 'In Progress...'
                    $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
                    ConvertFrom-Json | Select-Object  -ExpandProperty task* 

                    #User flag lookup
                    $var = Check-Flags -var $var -Name $Name -ID $ID -TaskType $TaskType

                    #Give this object a unique typename
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Automation.Tasks')
                        }
                    }
                return $var
                }
            }

Function Get-MDWorkflow {
    <#
    .Synopsis
       Get all workflows from Morpheus appliance
    .DESCRIPTION
       Gets all or one workflow based on the switch selection of Name, ID, Task. 
       Name can be used from position 0 without the switch to get a specific workflow by name.
       Utilizing the -Task parameter you can get all workflows that contain that task but the task id.

    .EXAMPLE
        Get-MDWorkflow -Name wf1
        
        This will return the data for a workflow named "wf1"
    .EXAMPLE
        Get-MDWorkflow task1
        
        This will return the data for a workflow named "wf1"
    .EXAMPLE
        Get-MDWorkflow -Task 100

        This will return all workflows with the task of id 100 in them
    #>
    [cmdletbinding()]
    Param (
        # Name of the Workflow
        [Parameter(Position=0)]
        [string]
        $Name,
        $ID,
        $Type,
        $Task
        )
    
    Try {
    
        $API = '/api/task-sets/'
        $var = @()

        #User Lookup
        Write-Progress -Activity "Collecting" -Status 'In Progress...'
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
        ConvertFrom-Json | Select-Object   -ExpandProperty task* 

        #User flag lookup
        $var = Check-Flags -var $var -Name $Name -ID $ID -Type $Type -Task $Task

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
    
Function Get-MDPowerSchedule {
    <#
    .Synopsis
       Get all power schedules from Morpheus appliance
    .DESCRIPTION
       Gets all or one power schedules based on the switch selection of Name, ID, Enabled. 
       Name can be used from position 0 without the switch to get a specific power schedule by name.

    .EXAMPLE
        Get-MDPowerSchedule
        
        This will return the data for all Power Schedules
    .EXAMPLE
        Get-MDPowerSchedule ps1
        
        This will return the data for a Power Schedule named "ps1"
    .EXAMPLE
        Get-MDPowerSchedule -Enabled True

        This will return all Power Schedules that are enabled

    #>
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
        Write-Progress -Activity "Collecting" -Status 'In Progress...'
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
    <#
    .Synopsis
       Get all task types from Morpheus appliance
    .DESCRIPTION
       Gets all or one task type based on the switch selection of Name, ID. 
       Name can be used from position 0 without the switch to get a specific task type by name.

        Available task types:
            - Ansible Playbook
            - Ansible Tower Job
            - Chef bootstrap
            - Email
            - Groovy Script
            - HTTP
            - Javascript
            - jRuby Script
            - Library Script
            - Library Template
            - PowerShell Script
            - Puppet Agent Install
            - Python Script
            - Restart
            - Shell Script
            - vRealize Orchestrator Workflow

    .EXAMPLE
        Get-MDTaskType
        
        This will return the data for all task types
    .EXAMPLE
        Get-MDTaskType Email
        
        This will return the data for a task type named "Email"

    #>
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
        Write-Progress -Activity "Collecting" -Status 'In Progress...'
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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

Function Get-MDVirtualImage {
    <#
    .Synopsis
       Get all virtual images from Morpheus appliance
    .DESCRIPTION
       Gets all or one virtual image based on the switch selection of Name, ID, ImageType and Uploaded. 
       Name can be used from position 0 without the switch to get a specific virtual image by name.

    .EXAMPLE
        Get-MDVirtualImage
        
        This will return the data for all Power Schedules
    .EXAMPLE
        Get-MDVirtualImage ps1
        
        This will return the data for a Power Schedule named "ps1"
    .EXAMPLE
        Get-MDVirtualImage -ImageType ami

        This will return all virtual images of the ami type
    .EXAMPLE
        Get-MDVirtualImage -Enabled True

        This will return all Power Schedules that are enabled

    #>
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
        Write-Progress -Activity "Collecting" -Status 'In Progress...'
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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

# This section contains functions for getting objects from the Infrastructure primary tab
#
# CURRENT CAPABILITIES:
# 1. Groups:    Get-MDGroup
# 2. Clouds:    Get-MDCloud
# 3. Clusters:  Get-MDCluster
# 4. Servers:   Get-MDServer
#
# TO BE COMPLETED:
# 1. 

Function Get-MDGroup {
    <#
    .Synopsis
       Get all groups from Morpheus appliance
    .DESCRIPTION
       Gets all or one groups based on the switch selection of Name 
       Name can be used from position 0 without the switch to get a specific cloud by name.

    .EXAMPLE
        Get-MDGroup
        
        This will return the data for all clouds
    .EXAMPLE
        Get-MDGroup cloud1
        
        This will return the data for a cloud named "cloud1"
    .EXAMPLE
        Get-MDGroup -Group "developers"

        This will return all clouds attached to the group "developers"

    #>
    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Infrastructure"
        $subZone = ""
        $construct = "Groups"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"
    
        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}


Function Get-MDCloud {
    <#
    .Synopsis
       Get all clouds from Morpheus appliance
    .DESCRIPTION
       Gets all or one clouds based on the switch selection of Name, ID, or CloudType 
       Name can be used from position 0 without the switch to get a specific cloud by name.
       Can accept pipeline input from the Get-MDGroup function

    .EXAMPLE
        Get-MDCloud
        
        This will return the data for all clouds
    .EXAMPLE
        Get-MDCloud cloud1
        
        This will return the data for a cloud named "cloud1"
    .EXAMPLE
        Get-MDCloud -CloudType "Amazon"

        This will return all clouds of the type "Amazon"

    .EXAMPLE
    Get-MDGroup "Developers" | Get-MDCloud

    This will get the object of the group "developers" and pipe that object to Get-MDCloud. This will return all clouds for the group.

    .EXAMPLE
    Get-MDGroup "Developers" | Get-MDCloud -CloudType "Amazon"

    This will get the object of the group "developers" and pipe that object to Get-MDCloud. This will return all clouds of type "Amazon" for the group.

    #>
    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Infrastructure"
        $subZone = ""
        $construct = "Zones"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"
    
        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}                                                                                                             

Function Get-MDCluster {
    <#
    .Synopsis
        Get all clusters from Morpheus appliance
    .DESCRIPTION
        Gets all or one clouds based on the switch selection of Name, ID, or Type 
        Name can be used from position 0 without the switch to get a specific cloud by name.
        Can accept pipeline input from the Get-MDCloud function

    .EXAMPLE
        Get-MDCluster
        
        This will return the data for all clouds
    .EXAMPLE
        Get-MDCluster cluster1
        
        This will return the data for a cloud named cluster1
    .EXAMPLE
        Get-MDCluster -Type "Kubernetes Cluster"

        This will return all clusters of the type "Kubernetes Cluster"

    .EXAMPLE
    Get-MDCloud "cloud1" | Get-MDCluster

    This will get the object of the cloud "cloud1" and pipe that object to Get-MDCluster. This will return all clusters for the cloud.

    #>
    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Infrastructure"
        $subZone = ""
        $construct = "Clusters"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"
    
        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}   

Function Get-MDNetwork {
<#
.Synopsis
    Get all networks from Morpheus appliance
.DESCRIPTION
    Gets all or one networks based on the switch selection of Name, ID
    Name can be used from position 0 without the switch to get a specific network by name.
    Can accept pipeline input from the Get-MDCloud function

.EXAMPLE
    Get-MDNetwork
    
    This will return the data for all networks
.EXAMPLE
    Get-MDNetwork network1
    
    This will return the data for a server named "network1"

.EXAMPLE
Get-MDCloud "cloud1" | Get-MDNetwork

This will get the object of the cloud "cloud1" and pipe that object to Get-MDNetwork. This will return all networks for the group.

#>

    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Infrastructure"
        $subZone = ""
        $construct = "Networks"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"

        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}

Function Get-MDNetworkGroup {
    <#
    .Synopsis
        Get all network groups from Morpheus appliance
    .DESCRIPTION
        Gets all or one network groups based on the switch selection of Name, ID
        Name can be used from position 0 without the switch to get a specific network group by name.
        Can accept pipeline input from the Get-MDAccount function
    
    .EXAMPLE
        Get-MDNetworkGroup
        
        This will return the data for all network groups
    .EXAMPLE
        Get-MDNetworkGroup networkgroup1
        
        This will return the data for a network group named "networkgroup1"
    
    .EXAMPLE
    Get-MDAccount "account1" | Get-MDNetworkGroup
    
    This will get the object of the tenant "tenant1" and pipe that object to Get-MDNetworkGroup. This will return all network groups for the tenant.
    
    #>

    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Infrastructure"
        $subZone = "Networks"
        $construct = "Groups"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"

        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}

Function Get-MDRouter {
    <#
    .Synopsis
        Get all network groups from Morpheus appliance
    .DESCRIPTION
        Gets all or one network groups based on the switch selection of Name, ID
        Name can be used from position 0 without the switch to get a specific network group by name.
        Can accept pipeline input from the Get-MDAccount function
    
    .EXAMPLE
        Get-MDNetworkGroup
        
        This will return the data for all network groups
    .EXAMPLE
        Get-MDNetworkGroup networkgroup1
        
        This will return the data for a network group named "networkgroup1"
    
    .EXAMPLE
    Get-MDAccount "account1" | Get-MDNetworkGroup
    
    This will get the object of the tenant "tenant1" and pipe that object to Get-MDNetworkGroup. This will return all network groups for the tenant.
    
    #>

    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Infrastructure"
        $subZone = "Networks"
        $construct = "Routers"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"

        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}

Function Get-MDIPPool {
    <#
    .Synopsis
        Get all network groups from Morpheus appliance
    .DESCRIPTION
        Gets all or one network groups based on the switch selection of Name, ID
        Name can be used from position 0 without the switch to get a specific network group by name.
        Can accept pipeline input from the Get-MDAccount function
    
    .EXAMPLE
        Get-MDNetworkGroup
        
        This will return the data for all network groups
    .EXAMPLE
        Get-MDNetworkGroup networkgroup1
        
        This will return the data for a network group named "networkgroup1"
    
    .EXAMPLE
    Get-MDAccount "account1" | Get-MDNetworkGroup
    
    This will get the object of the tenant "tenant1" and pipe that object to Get-MDNetworkGroup. This will return all network groups for the tenant.
    
    #>

    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Infrastructure"
        $subZone = "Networks"
        $construct = "Pools"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"

        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}

Function Get-MDDomain {
    <#
    .Synopsis
        Get all network groups from Morpheus appliance
    .DESCRIPTION
        Gets all or one network groups based on the switch selection of Name, ID
        Name can be used from position 0 without the switch to get a specific network group by name.
        Can accept pipeline input from the Get-MDAccount function
    
    .EXAMPLE
        Get-MDNetworkGroup
        
        This will return the data for all network groups
    .EXAMPLE
        Get-MDNetworkGroup networkgroup1
        
        This will return the data for a network group named "networkgroup1"
    
    .EXAMPLE
    Get-MDAccount "account1" | Get-MDNetworkGroup
    
    This will get the object of the tenant "tenant1" and pipe that object to Get-MDNetworkGroup. This will return all network groups for the tenant.
    
    #>

    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Name,
        [Parameter()]
        [string]
        $ID,
        # Input Object from the pipeline
        [Parameter(ValueFromPipeline=$true)]
        [System.Object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Infrastructure"
        $subZone = "Networks"
        $construct = "Domains"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = ("Get-MD$($construct)") -replace ".$"

        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}


### NEED TO WORK OUT ISSUES WITH CONSTRUCT WITH DASH IN THE NAME
# Function Get-MDSecurityGroup {
#     <#
#     .Synopsis
#         Get all network groups from Morpheus appliance
#     .DESCRIPTION
#         Gets all or one network groups based on the switch selection of Name, ID
#         Name can be used from position 0 without the switch to get a specific network group by name.
#         Can accept pipeline input from the Get-MDAccount function
    
#     .EXAMPLE
#         Get-MDNetworkGroup
        
#         This will return the data for all network groups
#     .EXAMPLE
#         Get-MDNetworkGroup networkgroup1
        
#         This will return the data for a network group named "networkgroup1"
    
#     .EXAMPLE
#     Get-MDAccount "account1" | Get-MDNetworkGroup
    
#     This will get the object of the tenant "tenant1" and pipe that object to Get-MDNetworkGroup. This will return all network groups for the tenant.
    
#     #>

#     [cmdletbinding()]
#     Param (
#         # Name of the object
#         [Parameter(Position=0)]
#         [string]
#         $Name,
#         [Parameter()]
#         [string]
#         $ID,
#         # Input Object from the pipeline
#         [Parameter(ValueFromPipeline=$true)]
#         [System.Object]
#         $InputObject
#         )

#     BEGIN {

#         # Set HTML config module
#         $zone = "Infrastructure"
#         $subZone = ""
#         $construct = "Security-Groups"

#         # Initialize var and return
#         $var = @()
#         $return = @()
#         $command = (("Get-MD$($construct -replace '[-]','')") -replace ".$")

#         Write-Verbose "START: $($command)"
#         Write-Verbose "Zone: $($zone)"
#         Write-Verbose "Sub-Zone: $($subZone)"
#         Write-Verbose "Construct: $($construct)"

#         # Setting Pipeline Data
#         Write-Verbose "Getting PSCallStack"
#         $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
#         Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
#         Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
#         $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
#         Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
#     }

#     PROCESS {

#         Try {
#             if ($subZone -eq ""){
#                 $API = "/api/$($construct.ToLower())"
#                 $InputConstruct = $construct
#             }else{
#                 $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
#                 $InputConstruct = ( ($subZone -replace ".$") + $construct)
#             }

#             $var = @()    

#             #API lookup
#             Write-Progress -Activity "Collecting" -Status 'In Progress...'
#             $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
#             Write-Verbose "var pre flag check:"
#             Write-Verbose $var

#             #User flag lookup
#             Write-Verbose "Attempting flag check with the following options" 
#             Write-Verbose "Input Object: $($InputObject)"
#             Write-Verbose "Construct: $($construct)"
#             Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
#             $var = Check-Flags -var $var -Name $Name -ID $ID -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
#             #Give this object a unique typename
#             if ($subzone -eq ""){
#                 Foreach ($Object in $var) {
#                     $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
#                     $return += $Object
#                     }
#                 }else{
#                     Foreach ($Object in $var) {
#                         $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
#                         $return += $Object
#                         }                  
#                 }             

#             return $return
#             }
#         Catch {
#             Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
#             Write-Host $err
#             }
#         }
#     END {
#         Write-Verbose "END: $($command)"
#     }
# }

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
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
        $Name
        )

    BEGIN {
        # Configure these variables based on function
        # XML config modules
        $zone = "Administration"
        $subZone = ""
        $construct = "accounts"

        # Function name
        $command = "Get-MDaccount"

        # Begin variablized calls
        if ($PipelineConstruct -eq "users"){

        }else{
        Write-Verbose "Start: $($command)"
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "PSCallStack: $($PipelineConstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline construct: $($PipelineConstruct)"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                $API = "/api/$($construct.ToLower())/"
                $InputConstruct = $construct
            }else{
                $API = "/api/$($subZone.ToLower())/$($construct.ToLower())"
                $InputConstruct = ( ($subZone -replace ".$") + $construct)
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConmstruct)"
            $var = Check-Flags -var $var -Name $Name -InputObject $InputObject -Construct $InputConstruct.ToLower() -PipelineConstruct $PipelineConstruct
            
            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }             

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any $($construct)." -ForegroundColor Red
            Write-Host $err
            }
        }
    END {
        Write-Verbose "END: $($command)"
    }
}



Function Get-MDBuild {
    Param (
        )

        $API = '/api/setup/check/'
        $var = @()

        #API lookup
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header |
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
        [Parameter(ValueFromPipeline=$true)]
        [object]
        $InputObject
        )

    BEGIN {

        # Set HTML config module
        $zone = "Administration"
        $subZone = ""
        $construct = "Users"
        $command = "Get-MDUser"

        # Set variable and return
        $var = @()
        $return = @()

        Write-Verbose "Start: $($command)"
        Write-Verbose "Getting pipeline count"
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {
        Try {
            
            #User Lookup
            if ($InputObject){
                $a = $InputObject.Id
                $API = "/api/accounts/$a/users"
                $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header -ErrorVariable err | ConvertFrom-Json
            }else{
                Write-Verbose "Getting all account ids"
                $accounts = Get-MDAccount | Select-Object -ExpandProperty id
                foreach ($a in $accounts) {
                    $API = "/api/accounts/$a/users"
                    $obj = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header -ErrorVariable err | ConvertFrom-Json | Select-Object -ExpandProperty $construct
                    $var += $obj
                    $PipelineConstruct = "usersOnly"
                    }
            }

            # User flag lookup

            $var = Check-Flags -var $var -Username $Username -InputObject $InputObject -Construct $construct.ToLower() -PipelineConstruct $PipelineConstruct

            #Give this object a unique typename
            if ($subzone -eq ""){
                Foreach ($Object in $var) {
                    $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($construct)")
                    $return += $Object
                    }
                }else{
                    Foreach ($Object in $var) {
                        $Object.PSObject.TypeNames.Insert(0,"Morpheus.$($zone).$($subZone).$($construct)")
                        $return += $Object
                        }                  
                }  

            return $return
            }
        Catch {
            Write-Host "Failed to retreive any users." -ForegroundColor Red
            $err
            }
        }
    END {
        Write-Verbose "End: $($command)"
    }
}
