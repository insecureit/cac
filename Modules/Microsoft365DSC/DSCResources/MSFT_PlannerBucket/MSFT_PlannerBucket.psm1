function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BucketId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanId,

        [Parameter()]
        [System.String]
        $GroupId,

        [Parameter()]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId
    )
    Write-Verbose -Message "Getting configuration of Planner Bucket {$Name}"

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    [array]$plans = Get-M365DSCPlannerPlansFromGroup -GroupId $GroupId `
                        -ApplicationID $ApplicationId `
                        -GlobalAdminAccount $GlobalAdminAccount
    [array]$plan = $plans | Where-Object -FilterScript {$_.Id -eq $PlanId}
    if ($null -eq $plan -or $plan.Length -eq 0)
    {
        [array]$plan = $plans | Where-Object -FilterScript {$_.Title -eq $PlanName}
        if ($null -eq $plan -or $plan.Length -eq 0)
        {
            Write-Verbose -Message "Waiting 10 seconds to get Plan"
            Start-Sleep -Seconds 10
            [array]$plan = $plans | Where-Object -FilterScript {$_.Title -eq $PlanName}
        }
        Write-Verbose -Message "Found Plan by Name {$PlanName} - {ID=$($Plan.Id)}"
    }

    if ($plan.Length -eq 1)
    {
        Write-Verbose -Message "Found Plan {$PlanName} with Id {$($plan.Id)}"
    }
    elseif ($plan.Length -gt 1)
    {
        Write-Verbose -Message "Found {$($plan.Length)} Plans with name {$PlanName}. Using the first instance to create the bucket."
        [array]$plan = $plan[0]
        Write-Verbose -Message "PlanID = {$($plan.Id)}"
    }
    else
    {
        Write-Verbose -Message "Could not find Plan {$PlanName}"
    }

    [Array]$buckets = Get-M365DSCPlannerBucketsFromPlan -GroupId $GroupId `
                          -PlanName $PlanName `
                          -ApplicationId $ApplicationId `
                          -PlanId $plan.Id `
                          -GlobalAdminAccount $GlobalAdminAccount
    [Array]$bucket = $buckets | Where-Object -FilterScript {$_.Id -eq $BucketId}
    if ($bucket.Length -eq 0)
    {
        [Array]$bucket = $buckets | Where-Object -FilterScript {$_.Name -eq $Name}
        Write-Verbose -Message "Found Existing Bucket by Name"
    }
    if ($bucket.Length -gt 1)
    {
        throw "Multiple Buckets with Name {$Name} were found for Plan with ID {$($plan.Id)}." + `
            " Please use the BucketId property to identify the exact bucket."
    }

    if ($null -eq $bucket)
    {
        Write-Verbose -Message "Could not find existing Bucket"
        $results = @{
            Name               = $Name
            PlanName           = $PlanName
            PlanId             = $PlanId
            BucketId           = $bucket.Id
            GroupId            = $GroupId
            Ensure             = "Absent"
            ApplicationId      = $ApplicationId
            GlobalAdminAccount = $GlobalAdminAccount
        }
        return $results
    }

    $results = @{
        Name               = $Name
        PlanName           = $PlanName
        PlanId             = $PlanId
        BucketId           = $bucket.Id
        GroupId            = $GroupId
        Ensure             = "Present"
        ApplicationId      = $ApplicationId
        GlobalAdminAccount = $GlobalAdminAccount
    }
    Write-Verbose -Message "Get-TargetResource Result: `n $(Convert-M365DscHashtableToString -Hashtable $results)"
    return $results
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BucketId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanId,

        [Parameter()]
        [System.String]
        $GroupId,

        [Parameter()]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId
    )
    Write-Verbose -Message "Setting configuration of Planner Bucket {$Name}"

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq 'Present' -and $currentValues.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Getting all plans in Group {$GroupId}"
        [array]$plans = Get-M365DSCPlannerPlansFromGroup -GroupId $GroupId `
                -ApplicationID $ApplicationId `
                -GlobalAdminAccount $GlobalAdminAccount
        [array]$plan = $plans | Where-Object -FilterScript {$_.Id -eq $PlanId}
        if ($null -eq $plan -or $plan.Length -eq 0)
        {
            Write-Verbose -Message "Plan was not found by ID"
            [array]$plan = $plans | Where-Object -FilterScript {$_.Title -eq $PlanName}
            if ($null -eq $plan -or $plan.Length -eq 0)
            {
                Start-Sleep -Seconds 10
                [array]$plan = $plans | Where-Object -FilterScript {$_.Title -eq $PlanName}
                if ($null -eq $plan)
                {
                    Write-Verbose -Message "Could not retrieve project Plan {$PlanName}"
                    throw "Could not retrieve project Plan {$PlanName}"
                }
            }
        }

        if ($plan.Length -gt 1)
        {
            Write-Verbose -Message "Found multiple instance of the Plan"
            [array]$plan = $plan[0]
        }
        Write-Verbose -Message "Planner Bucket {$Name} doesn't already exist. Creating it."
        New-M365DSCPlannerBucket -Name $Name -PlanId $plan.Id `
            -ApplicationId $ApplicationId `
            -GlobalAdminAccount $GlobalAdminAccount | Out-Null
    }
    elseif ($Ensure -eq 'Present' -and $currentValues.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Planner Bucket {$Name} already exists for Plan {$PlanName} with ID {$($plan.Id)}, but is not in the Desired State. Updating it."
        #Update-MGPlannerPlan @SetParams
    }
    elseif ($Ensure -eq 'Absent' -and $currentValues.Ensure -eq 'Present')
    {
        Write-Verbose -Message "This resource doesn't allow for removal of Planner Bucket."
        # TODO - Implement when available in the MSGraph PowerShell SDK
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BucketId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanId,

        [Parameter()]
        [System.String]
        $GroupId,

        [Parameter()]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId
    )

    Write-Verbose -Message "Testing configuration of Planner Bucket {$Name}"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = $PSBoundParameters
    $ValuesToCheck.Remove('ApplicationId') | Out-Null
    $ValuesToCheck.Remove('TenantId') | Out-Null
    $ValuesToCheck.Remove('CertificateThumbprint') | Out-Null
    $ValuesToCheck.Remove('BucketId') | Out-Null
    $ValuesToCheck.Remove('PlanId') | Out-Null
    $TestResult = Test-Microsoft365DSCParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $ValuesToCheck.Keys

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationId,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )
    $InformationPreference = 'Continue'

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Platform 'AzureAD' `
        -InboundParameters $PSBoundParameters

    [array]$groups = Get-AzureADGroup -All:$true

    $i = 1
    $content = ''
    foreach ($group in $groups)
    {
        Write-Information "    [$i/$($groups.Length)] $($group.DisplayName) - {$($group.ObjectID)}"
        try
        {
            [Array]$plans = Get-M365DSCPlannerPlansFromGroup -GroupId $group.ObjectId `
                                -ApplicationId $ApplicationId `
                                -GlobalAdminAccount $GlobalAdminAccount

            $j = 1
            foreach ($plan in $plans)
            {
                Write-Information "        [$j/$($plans.Length)] $($plan.Title)"
                $buckets = Get-M365DSCPlannerBucketsFromPlan -PlanName $plan.Title `
                               -GroupId $group.ObjectId `
                               -PlanId $plan.Id `
                               -ApplicationId $ApplicationId `
                               -GlobalAdminAccount $GlobalAdminAccount
                $k = 1
                foreach ($bucket in $buckets)
                {
                    Write-Information "            [$k/$($buckets.Length)] $($bucket.Name)"
                    $params = @{
                        Name               = $bucket.Name
                        PlanName           = $plan.Title
                        GroupId            = $Group.ObjectId
                        ApplicationId      = $ApplicationId
                        GlobalAdminAccount = $GlobalAdminAccount
                    }
                    $result = Get-TargetResource @params
                    $content += "        PlannerBucket " + (New-GUID).ToString() + "`r`n"
                    $content += "        {`r`n"
                    $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
                    $content += $currentDSCBlock
                    $content += "        }`r`n"
                    $k++
                }
                $j++
            }
            $i++
        }
        catch
        {
            Write-Error $_
            Write-Verbose -Message $_
        }
    }
    return $content
}
function New-M365DSCPlannerBucket
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanId,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationId
    )
    $uri = "https://graph.microsoft.com/v1.0/planner/buckets"
    $body = [System.Text.StringBuilder]::new()
    $body.Append("{") | Out-Null
    $body.Append("`"planId`": `"$PlanId`",") | Out-Null
    $body.Append("`"name`": `"$($Name.Replace('"', '\"'))`"") | Out-Null
    $body.Append("}") | Out-Null
    $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
        -ApplicationId $ApplicationId `
        -Uri $uri `
        -Method "POST" `
        -Body $body.ToString()
}

function Get-M365DSCPlannerPlansFromGroup
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupId,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationId
    )
    $results = @()
    $uri = "https://graph.microsoft.com/v1.0/groups/$GroupId/planner/plans"
    $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
        -ApplicationId $ApplicationId `
        -Uri $uri `
        -Method Get
    foreach ($plan in $taskResponse.value)
    {
        $results += @{
            Id    = $plan.id
            Title = $plan.title
        }
    }
    return $results
}

function Get-M365DSCPlannerBucketsFromPlan
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupId,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationId
    )
    $results = @()
    $uri = "https://graph.microsoft.com/v1.0/planner/plans/$PlanId/buckets"
    $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
        -ApplicationId $ApplicationId `
        -Uri $uri `
        -Method Get
    foreach ($bucket in $taskResponse.value)
    {
        $results += @{
            Name     = $bucket.name.Replace('“', '"').Replace('”', '"')
            PlanName = $PlanName
            Id       = $bucket.id
            GroupId  = $GroupId
        }
    }
    return $results
}

Export-ModuleMember -Function *-TargetResource
