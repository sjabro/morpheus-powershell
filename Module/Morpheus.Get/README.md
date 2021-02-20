# Morpheus GET

This module performs all of the get functions for the PowerShell module. Some of the functions can take pipeline input from others. See teh Pipeline Workbook spreadsheet.

Here is a sample of the code and how to get working with it quickly.
The function code is built to be as reusable as possible.
Under the BEGIN section, the first set of Variables are for calling to the formatting xml. These variables are also tied directly to the API calls. 
There are three sections
 - Zone
 - Subzone
 - Construct

### Zone

Zone is the primary zone of the construct which you are trying to call.
In the example we have here zone is "Provisioning". This identifies the primary category of the construct.

### SubZone

The subzone is the secondary or subcategory of the construct. This is used when an API call needs to go a layer deeper. An example of this is instance types. The API endpoint for instance types is /api/library/instance-types. The subzone in that case would be "Library". Our example does not have a subzone so can be left blank.

### Construct

This is the construct that you wish to deal with as designated by the API endpoint. Some constructs hold the naming convention, but others do not due to advancements in naming conventions.
An example of this would be workflows. In the UI, you look for workflows and the CMDLET is called Get-MDWorkflow as that is what the user would expect. However, the API endpoint name is actually task-sets. So for workflows, the construct would actually be task-sets.
In our example below, the construct is tasks as that is the construct AND API endpoint name.

Under most circumstances these should be the only edits you need to make to the code. So you can copy paste this to create a get function and update that vars and be good to go. 

To get the cleaner formatted output, you will want to ensure that there is a module for the construct in Morpheus.Get.Format.ps1xml. These modules are also based off of the Zone, SubZone, Construct idea. So you just need to be sure there is a module that aligns with this.

EXAMPLE:

For our example below there is a module called Morpheus.Provisioning.Tasks which handles the columns and formatting

For instance types there is module called Morpheus.Provisioning.Library.Instance-Types

You can set up the formatting as desired for each of these constructs to return the most pertinent data for it

```
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
            $API = "/api/$($construct.ToLower())/"
            $var = @()    

            #API lookup
            Write-Progress -Activity "Collecting" -Status 'In Progress...'
            $var = Invoke-WebRequest -Method GET -Uri ($URL + $API + "?max=10000") -Headers $Header  -ErrorVariable err | ConvertFrom-Json
            $returnConstruct = $var | Get-Member -MemberType NoteProperty | Where-Object {$_.Definition -like "Object*"}
            Write-Verbose "var pre flag check:"
            Write-Verbose $var

            #User flag lookup
            Write-Verbose "Attempting flag check with the following options" 
            Write-Verbose "Input Object: $($InputObject)"
            Write-Verbose "Construct: $($construct)"
            Write-Verbose "Pipeline Construct: $($PipelineConstruct)"
            $var = Compare-Flags -var $var -Name $Name -InputObject $InputObject -Construct $returnConstruct.Name -PipelineConstruct $PipelineConstruct
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
```
