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
                                                                                

# This section contains functions for getting objects from the Operations primary tab
#
# Current capabilities:
# 1. Billing
# 2. History
#
#  To be completed:

Function Get-MDReport {
    <#
    .Synopsis
       Get all tasks from Morpheus appliance
    .DESCRIPTION
       Gets all or one task based on the switch selection of Name, ID.
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
        $zone = "Operations"
        $subZone = ""
        $construct = "Reports"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDBudget {
    <#
    .Synopsis
       Get all tasks from Morpheus appliance
    .DESCRIPTION
       Gets all or one task based on the switch selection of Name, ID.
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
        $zone = "Operations"
        $subZone = ""
        $construct = "Budgets"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDInvoice {
    <#
    .Synopsis
       Get all tasks from Morpheus appliance
    .DESCRIPTION
       Gets all or one task based on the switch selection of Name, ID.
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
        $zone = "Operations"
        $subZone = ""
        $construct = "Invoices"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
        $var = Compare-Flags -var $var -Name $Name -InputObject $InputObject

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
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json | Select-Object  -ExpandProperty process* 

        #User flag lookup
        $var = Compare-Flags -var $var -InstanceID $InstanceID -ServerID $ServerID

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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }

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
        $subZone = ""
        $construct = "Apps"

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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
        $construct = "Blueprints"

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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDJob {
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
        $construct = "Jobs"

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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

# AUTOMATION

Function Get-MDTask {
    <#
    .Synopsis
       Get all tasks from Morpheus appliance
    .DESCRIPTION
       Gets all or one task based on the switch selection of Name, ID.
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
        $construct = "Tasks"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
        $construct = "Task-Sets"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = (("Get-MD$($construct -replace '[-]','')") -replace ".$")
    
        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        # Write-Verbose "Getting PSCallStack"
        # $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        # Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        # Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        # $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        # Set PipelineContruct manually due to naming differences
        $PipelineConstruct = $construct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            Write-Verbose "Var: $($var)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }

            Write-Verbose "Var: $($var)"
            
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
    
Function Get-MDPowerSchedule {
    <#
    .Synopsis
       Get all tasks from Morpheus appliance
    .DESCRIPTION
       Gets all or one task based on the switch selection of Name, ID.
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
        $construct = "Power-Schedules"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDExecuteSchedule {
    <#
    .Synopsis
       Get all tasks from Morpheus appliance
    .DESCRIPTION
       Gets all or one task based on the switch selection of Name, ID.
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
        $construct = "Execute-Schedules"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }
            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

# Function Get-MDTaskType {
#     <#
#     .Synopsis
#        Get all task types from Morpheus appliance
#     .DESCRIPTION
#        Gets all or one task type based on the switch selection of Name, ID. 
#        Name can be used from position 0 without the switch to get a specific task type by name.

#         Available task types:
#             - Ansible Playbook
#             - Ansible Tower Job
#             - Chef bootstrap
#             - Email
#             - Groovy Script
#             - HTTP
#             - Javascript
#             - jRuby Script
#             - Library Script
#             - Library Template
#             - PowerShell Script
#             - Puppet Agent Install
#             - Python Script
#             - Restart
#             - Shell Script
#             - vRealize Orchestrator Workflow

#     .EXAMPLE
#         Get-MDTaskType
        
#         This will return the data for all task types
#     .EXAMPLE
#         Get-MDTaskType Email
        
#         This will return the data for a task type named "Email"

#     #>
#     Param (
#         # Name of the Task Type
#         [Parameter(Position=0)]
#         [string]
#         $Name,
#         $ID
#         )

#     Try {

#         $API = '/api/task-types/'
#         $var = @()

#         #API lookup
#         Write-Progress -Activity "Collecting" -Status 'In Progress...'
#         $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
#         ConvertFrom-Json | Select-Object  -ExpandProperty task* 

#         #User flag lookup
#         $var = Compare-Flags -var $var -Name $Name -ID $ID

#         #Give this object a unique typename
#         Foreach ($Object in $var) {
#             $Object.PSObject.TypeNames.Insert(0,'Morpheus.Provisioning.Automation.Tasks.Types')
#             }

#         return $var

#         }
#     Catch {
#         Write-Host "Failed to retreive any task types." -ForegroundColor Red
#         }
#     }

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
        $construct = "Virtual-Images"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDInstanceType {
    <#
    .Synopsis
       Get all instance types from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the instance types from the Morpheus appliance
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
        $subZone = "Library"
        $construct = "Instance-Types"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDLayout {
    <#
    .Synopsis
       Get all instance types from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the instance types from the Morpheus appliance
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
        $subZone = "Library"
        $construct = "Layouts"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDOptionType {
    <#
    .Synopsis
       Get all option types from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the option types from the Morpheus appliance
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
        $subZone = "Library"
        $construct = "Option-Types"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDOptionList {
    <#
    .Synopsis
       Get all option lists from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the option lists from the Morpheus appliance
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
        $subZone = "Library"
        $construct = "Option-Type-Lists"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDFileTemplate {
    <#
    .Synopsis
       Get all file templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the file template from the Morpheus appliance
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
        $subZone = "Library"
        $construct = "container-templates"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDSpecTemplate {
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        $subZone = "Library"
        $construct = "Spec-Templates"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDClusterLayout {
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        $subZone = "Library"
        $construct = "Cluster-Layouts"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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


#########################################################################################################
### START CLOUD  & CLUSTER SPECIFIC CONSTRUCTS
#########################################################################################################

Function Get-MDDatastore {
    <#
    .Synopsis
       Get all Datastores for the Piped in Cloud or Cluster. This CMDLet required a cloud or cluster inputobject from the pipeline.
    .DESCRIPTION
       Lists all of the following objects from the piped in cloud
       - Security Groups

    .EXAMPLE
        Get-MDCloud mycloud | Get-MDDataStore

    .EXAMPLE
        Get-MDCluster mycluster | Get-MDDataStore

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
        # Customized for this CMDLet
        # if ($InputObject.config){
        #     $construct = "data-stores"
        # }else {
        #     $construct = "datastores"
        # }

        # Initialize var and return
        $var = @()
        $return = @()
        #$command = ("Get-MD$($construct)") -replace ".$"
    
        Write-Verbose "START: $($command)"
        Write-Verbose "Zone: $($zone)"
        Write-Verbose "Sub-Zone: $($subZone)"
        #Write-Verbose "Construct: $($construct)"

        # Setting Pipeline Data
        Write-Verbose "Getting PSCallStack"
        $PipelineConstruct = (Get-PSCallStack).InvocationInfo[1].MyCommand.Definition
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
        Write-Verbose "Calling Get-PipelineConstruct cmdlet to set pipelineconstruct"
        $PipelineConstruct = Get-PipelineConstruct $PipelineConstruct.ToLower()
        Write-Verbose "Pipeline Construct is: $($pipelineconstruct)"
    }

    PROCESS {
        Write-Verbose $InputObject
        if ($InputObject.config){
            $construct = "Data-Stores"
        }else {
            $construct = "Datastores"
        }
        Try {
            #Customized for this CMDLet
            if ($construct -eq "data-stores"){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDResourcePool {
    <#
    .Synopsis
       Get all Resource Pools from the provided cloud
    .DESCRIPTION
       Gets all or one resource pool from the cloud object provided via the pipeline
    .EXAMPLE
        Get-MDCloud mycloud | Get-MDResourcePool
        
        This will return the data for all Resource Pools from the cloud "mycloud"
    .EXAMPLE
        Get-MDCloud mycloud | Get-MDResourcePool myrp
        
        This will return the data for resource pool "myrp" from the cloud "mycloud"
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
        $construct = "Resource-Pools"

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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDFolder {
    <#
    .Synopsis
       Get all Folders from the provided cloud
    .DESCRIPTION
       Gets all or one folder from the cloud object provided via the pipeline
    .EXAMPLE
        Get-MDCloud mycloud | Get-MDFolder
        
        This will return the data for all Folders from the cloud "mycloud"
    .EXAMPLE
        Get-MDCloud mycloud | Get-MDFolder myrp
        
        This will return the data for resource folder "myrp" from the cloud "mycloud"
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
        $construct = "Folders"

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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/zones/$($InputObject.id)/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/clusters/$($InputObject.id)/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

####################################################################
### END CLOUD SPECIFIC CONSTRUCTS
####################################################################

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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
Function Get-MDSecurityGroup {
    <#
    .Synopsis
        Get all network groups from Morpheus appliance
    .DESCRIPTION
        Gets all or one security group
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
        $construct = "Security-Groups"

        # Initialize var and return
        $var = @()
        $return = @()
        $command = (("Get-MD$($construct -replace '[-]','')") -replace ".$")

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
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        $zone = "Tools"
        $subZone = ""
        $construct = "Cypher"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
                                                                                                           
                                                                                                           
Function Get-MDTenant {
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        $zone = "Administration"
        $subZone = ""
        $construct = "Accounts"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDServicePlan {
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        $zone = "Administration"
        $subZone = ""
        $construct = "Service-Plans"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDPriceSet {
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        $zone = "Administration"
        $subZone = ""
        $construct = "Price-Sets"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDPrice {
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        $zone = "Administration"
        $subZone = ""
        $construct = "Prices"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDRole {
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
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
        $zone = "Administration"
        $subZone = ""
        $construct = "Roles"

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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

Function Get-MDUser {
    <#
    .Synopsis
       Get all spec templates from Morpheus appliance
    .DESCRIPTION
       Gets all or one of the spec template from the Morpheus appliance
    #>
    [cmdletbinding()]
    Param (
        # Name of the object
        [Parameter(Position=0)]
        [string]
        $Username,
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
        $zone = "Administration"
        $subZone = ""
        $construct = "Users"

        # Settign name to Username due to unique naming for users
        $Name = $Username

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
        if ($PipelineConstruct -eq "workflows"){
            $PipelineConstruct = "taskSets"
        }
    }

    PROCESS {

        Try {
            if ($subZone -eq ""){
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    $API = "/api/$($construct.ToLower())?username=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }else{
                If ($Name){
                    Write-Verbose "Name Specified. Setting API"
                    # Custom search for username
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?username=$($Name)"
                    # $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?name=$($Name)"
                    Write-Verbose "API set to: $($API)"
                }elseif ($ID) {
                    Write-Verbose "ID Specified. Setting API"
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())/$($ID)"
                    Write-Verbose "API set to: $($API)"
                }else {
                    $API = "/api/$($subZone.ToLower())/$($construct.ToLower())?max=10000"
                    Write-Verbose "API set to: $($API)"
                }
            }

            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            if ($Name){
                $objName = $construct.replace("-","")
                $var = $var.$objName
            }elseif ($ID) {
                $objName = $construct.replace("-","")
                $var = $var.(($objName) -replace ".$")
            }else{
                $var = Compare-Flags -var $var -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
            }
            
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
        $var = Invoke-WebRequest -Method GET -Uri ($URL + $API) -Headers $Header |
        ConvertFrom-Json

    return $var

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
        $var = Compare-Flags -var $var -Name $Name -ID $ID -Enabled $Enabled -PolicyType $PolicyType

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