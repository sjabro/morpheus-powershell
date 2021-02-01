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

    #Check if a Morpheus Instance is Connected
    If ($Header) {
        #Ensure a Filter is Defined
        If ((!$ID) -and (!$Name) -and (!$Cloud) -and (!$CloudId) -and (!$Group) -and (!$GroupId)) {
            Write-Host "No Arguments Supplied!" -ForegroundColor Red
            }
        Else {
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
        }
    Else {
        Write-Host "Not currently connected to a Morpheus Instance.  Run 'Connect-Morpheus' to establish a connection" -ForegroundColor Red
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

    #Check if a Morpheus Instance is Connected
    If ($Header) {
        #Ensure a Filter is Defined
        If ((!$ID) -and (!$Name) -and (!$PolicyType) -and (!$Enabled)) {
            Write-Host "No Arguments Supplied!" -ForegroundColor Red
            }
        Else {
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
                        Invoke-WebRequest -Method Delete -Uri ($URL + $API + $v.id + '?') -Headers $Header
                        }
                    }
                }
            Catch {
                Write-Host "Failed to retreive any matching policies." -ForegroundColor Red
                }
            }
        }
    Else {
        Write-Host "Not currently connected to a Morpheus Instance.  Run 'Connect-Morpheus' to establish a connection" -ForegroundColor Red
        }
    }