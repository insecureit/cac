function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        [Parameter()]
        [System.String[]]
        $AssignedUsers,

        [Parameter()]
        [System.String]
        $Notes,

        [Parameter()]
        [System.String]
        $BucketName,

        [Parameter()]
        [System.String]
        $StartDateTime,

        [Parameter()]
        [System.String]
        $CompletedDateTime,

        [Parameter()]
        [System.String]
        $DueDateTime,

        [Parameter()]
        [System.String[]]
        $Categories,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Attachments,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Checklist,

        [Parameter()]
        [ValidateRange(0, 100)]
        [System.Uint32]
        $PercentComplete,

        [Parameter()]
        [ValidateRange(0, 10)]
        [System.UInt32]
        $Priority,

        [Parameter()]
        [ValidateSet("automatic", "description", "noPreview", "reference", "checklist")]
        [System.String]
        $PreviewType,

        [Parameter()]
        [System.String]
        $ConversationThreadId,

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
    Write-Verbose -Message "Getting configuration of Planner Task {$Title}"

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $nullReturn = @{
        PlanName              = $PlanName
        Title                 = $Title
        Ensure                = "Absent"
        ApplicationId         = $ApplicationId
        GlobalAdminAccount    = $GlobalAdminAccount
    }

    try
    {
        [PlannerTaskObject].GetType() | Out-Null
    }
    catch
    {
        $ModulePath = Join-Path -Path $PSScriptRoot `
            -ChildPath "../../Modules/GraphHelpers/PlannerTaskObject.psm1"
        $usingScriptBody = "using module '$ModulePath'"
        $usingScript = [ScriptBlock]::Create($usingScriptBody)
        . $usingScript
    }
    #Write-Verbose -Message "Populating task {$Title} from the Get method"
    $task = [PlannerTaskObject]::new()
    #$task.PopulateById($GlobalAdminAccount, $ApplicationId, $TaskId)

    $PlanId = Get-M365DSCPlannerPlanIdByName -ApplicationId $ApplicationId `
        -GlobalAdminAccount $GlobalAdminAccount `
        -PlanName $PlanName `
        -GroupId $GroupId

    Write-Verbose -Message "Retrieve PlanID {$PlanId}"
    if ([System.String]::IsNullOrEmpty($task.Title))
    {
        Write-Verbose -Message "We couldn't find the task by ID, trying to find it by Title"
        $allTasks = Get-M365DSCPlannerTasksFromPlan -PlanId $PlanId `
            -GlobalAdminAccount $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -TaskTitle $Title
        Write-Verbose -Message "Retrieved all tasks for PlanID {$PlanId}"

        [array]$tasksWithMatchingTitle = $allTasks

        if ($null -eq $tasksWithMatchingTitle)
        {
            Write-Verbose -Message "Couldn't find any tasks in plan {$PlanId} matching title {$Title}"
            return $nullReturn
        }
        Write-Verbose -Message "Found at least one Task with title {$Title} in Plan {$PlanName}"
        # Ensure a few extra fields are a match before assuming the task already exists;
        $foundMatch = $false

        $i = 1
        foreach ($match in $tasksWithMatchingTitle)
        {
            #region Bucket Name
            $BucketNameValue = Get-M365DSCPlannerBucketNameByTaskId -ApplicationId $ApplicationId `
                        -TaskId $match.TaskId `
                        -GlobalAdminAccount $GlobalAdminAccount
            Write-Verbose "Retrieved Bucket {$BucketNameValue}"
            #endregion

            Write-Verbose -Message "Task #$i Values: $(Convert-M365DscHashtableToString -Hashtable $match)"
            Write-Verbose -Message "----------------------"
            Write-Verbose -Message "BUCKETNAME: {$BucketName} == {$BucketNameValue}"
            if ($BucketName -eq $BucketNameValue)
            {
                Write-Verbose -Message "TRUE"
            }
            else
            {            
                Write-Verbose -Message "FALSE"
            }
            Write-Verbose -Message "NOTES: {$Notes} == {$($match.Notes)}"
            if ($Notes -eq $match.Notes)
            {
                Write-Verbose -Message "TRUE"
            }
            else
            {            
                Write-Verbose -Message "FALSE"
            }
            Write-Verbose -Message "DUEDATETIME:{$DueDateTime} == {$($match.DueDateTime)}"
            if ($DueDateTime -eq $match.DueDateTime)
            {
                Write-Verbose -Message "TRUE"
            }
            else
            {            
                Write-Verbose -Message "FALSE"
            }
            Write-Verbose -Message "COMPLETEDDATETIME:{$CompletedDateTime} == {$($match.CompletedDateTime)}"
            if ($CompletedDateTime -eq $match.CompletedDateTime)
            {
                Write-Verbose -Message "TRUE"
            }
            else
            {            
                Write-Verbose -Message "FALSE"
            }
            Write-Verbose -Message "STARTDATETIME:{$StartDateTime} == {$($match.StartDateTime)}"
            if ($StartDateTime -eq $match.StartDateTime)
            {
                Write-Verbose -Message "TRUE"
            }
            else
            {            
                Write-Verbose -Message "FALSE"
            }
            Write-Verbose -Message "PercentComplete:{$PercentComplete} == {$($match.PercentComplete)}"
            if ($PercentComplete -eq $match.PercentComplete)
            {
                Write-Verbose -Message "TRUE"
            }
            else
            {            
                Write-Verbose -Message "FALSE"
            }
            $i = 1
            $allCheckListItemMatch = $true
            if ($CheckList.Length -ne $match.CheckList.Length)
            {
                Write-Verbose -Message "Number of Checklist item don't match. Current {$($match.CheckList.Length)} != Target {$($CheckList.Length)"
                $allCheckListItemMatch = $false
            }
            else
            {
                foreach ($item in $Checklist)
                {
                    $foundItemMatch = $false
                    foreach ($currentItem in $match.CheckList)
                    {
                        Write-Verbose -Message "CheckList #$i {$($item.title)} == {$($currentItem.Title)}"
                        if ($item.title -eq $currentItem.Title)
                        {
                            Write-Verbose -Message "TRUE"
                            $foundItemMatch = $true
                            break
                        }  
                        else
                        {            
                            Write-Verbose -Message "FALSE"
                        } 
                    }
                    if (-not $foundItemMatch)
                    {
                        Write-Verbose "At least one checkList item was found not to match."
                        $allCheckListItemMatch = $false
                        break
                    }
                }
            }
            Write-Verbose -Message "MATCH = $($match | Out-String)"
            if ($Notes -eq $match.Notes -and $PercentComplete -eq $match.PercentComplete -and $BucketName -eq $BucketNameValue -and
            $DueDateTime -eq $match.DueDateTime -and $CompletedDateTime -eq $match.CompletedDateTime -and $StartDateTime -eq $match.StartDateTime -and
            $allCheckListItemMatch)
            {
                Write-Verbose -Message "Found a match by properties"
                $foundMatch = $true                
                $task.PopulateById($GlobalAdminAccount, $ApplicationId, $match.TaskId)
                break
            }
            $i++
        }

        if (-not $foundMatch)
        {
            Write-Verbose -Message "While multiple tasks were found to have the same title, the other fields did not match."
            return $nullReturn
        }

        Write-Verbose -Message "Found at least one task with same title and matching other fields' values."
    }

    Write-Verbose -Message "Task {$Title} was successfully populated from the Get method."
    #region Bucket Name
    $BucketNameValue = Get-M365DSCPlannerBucketNameByTaskId -ApplicationId $ApplicationId `
                        -TaskId $match.TaskId `
                        -GlobalAdminAccount $GlobalAdminAccount
    Write-Verbose "Retrieved Bucket {$BucketNameValue}"
    #endregion

    #region Plan Name
    [array]$plan = Get-M365DSCPlannerPlansFromGroup -ApplicationId $ApplicationId `
                -GroupId $GroupId `
                -GlobalAdminAccount $GlobalAdminAccount | Where-Object -FilterScript {$_.Title -eq $PlanName}
    $PlanNameValue = $plan[0].Title
    #endregion
    
    $NotesValue = ""
    if ($null -ne $task.Notes)
    {
        $NotesValue = $task.Notes
    }

    #region Task Assignment
    if ($task.Assignments.Length -gt 0)
    {
        Write-Verbose "The Task has assignments"
        Test-MSCloudLogin -Platform AzureAD -CloudCredential $GlobalAdminAccount
        $assignedValues = @()
        foreach ($assignee in $task.Assignments)
        {
            try
            {
                $user = Get-AzureADUser -ObjectId $assignee
                $assignedValues += $user.UserPrincipalName
            }
            catch
            {
                Write-Verbose -Message $_
            }
        }
    }
    #endregion

    #region Task Categories
    Write-Verbose -Message "Retrieving Categories"
    $categoryValues = @()
    foreach ($category in $task.Categories)
    {
        $categoryValues += $category
    }
    #endregion

    $StartDateTimeValue = $null
    if ($null -ne $task.StartDateTime)
    {
        $StartDateTimeValue = $task.StartDateTime
    }
    $DueDateTimeValue = $null
    if ($null -ne $task.DueDateTime)
    {
        $DueDateTimeValue = $task.DueDateTime
    }
    
    Write-Verbose -Message "Returning Values"
    $results = @{
        GroupId               = $GroupId
        PlanName              = $PlanNameValue
        TaskId                = $TaskId
        Title                 = $Title
        AssignedUsers         = $assignedValues
        Categories            = $categoryValues
        Attachments           = $task.Attachments
        Checklist             = $task.Checklist
        BucketName            = $BucketNameValue
        Priority              = $task.Priority
        ConversationThreadId  = $task.ConversationThreadId
        PercentComplete       = $task.PercentComplete
        PreviewType           = $task.PreviewType
        StartDateTime         = $StartDateTimeValue
        DueDateTime           = $DueDateTimeValue
        CompletedDateTime     = $task.CompletedDateTime
        Notes                 = $NotesValue.Replace("`?", "`"").Replace("`?", "`"").Replace("`?", "'").Replace("`?", "...")
        Ensure                = "Present"
        ApplicationId         = $ApplicationId
        GlobalAdminAccount    = $GlobalAdminAccount
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
        $PlanName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        [Parameter()]
        [System.String[]]
        $AssignedUsers,

        [Parameter()]
        [System.String]
        $Notes,

        [Parameter()]
        [System.String]
        $BucketName,

        [Parameter()]
        [System.String]
        $Bucket,

        [Parameter()]
        [System.String]
        $StartDateTime,

        [Parameter()]
        [System.String]
        $CompletedDateTime,

        [Parameter()]
        [System.String]
        $DueDateTime,

        [Parameter()]
        [System.String[]]
        $Categories,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Attachments,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Checklist,

        [Parameter()]
        [ValidateRange(0, 100)]
        [System.Uint32]
        $PercentComplete,

        [Parameter()]
        [ValidateRange(0, 10)]
        [System.UInt32]
        $Priority,

        [Parameter()]
        [ValidateSet("automatic", "description", "noPreview", "reference", "checklist")]
        [System.String]
        $PreviewType,

        [Parameter()]
        [System.String]
        $ConversationThreadId,

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
    Write-Verbose -Message "Setting configuration of Planner Task {$Title}"

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentValues = Get-TargetResource @PSBoundParameters

    try
    {
        [PlannerTaskObject].GetType() | Out-Null
    }
    catch
    {
        $ModulePath = Join-Path -Path $PSScriptRoot `
            -ChildPath "../../Modules/GraphHelpers/PlannerTaskObject.psm1"
        $usingScriptBody = "using module '$ModulePath'"
        $usingScript = [ScriptBlock]::Create($usingScriptBody)
        . $usingScript
    }
    $task = [PlannerTaskObject]::new()

    $PlanId = Get-M365DSCPlannerPlanIdByName -GlobalAdminAccount $GlobalAdminAccount `
        -ApplicationId $ApplicationId `
        -GroupId $GroupId `
        -PlanName $PlanName
    $task.BucketId             = $Bucket
    $task.Title                = $Title
    $task.PlanId               = $PlanId
    $task.PercentComplete      = $PercentComplete
    $task.PreviewType          = $PreviewType
    $task.StartDateTime        = $StartDateTime
    $task.DueDateTime          = $DueDateTime
    $task.Priority             = $Priority
    $task.Notes                = $Notes
    $task.ConversationThreadId = $ConversationThreadId

    #region Assignments
    if ($AssignedUsers.Length -gt 0)
    {
        Test-MSCloudLogin -Platform AzureAD -CloudCredential $GlobalAdminAccount
        $AssignmentsValue = @()
        foreach ($userName in $AssignedUsers)
        {
            try
            {
                $user = Get-AzureADUser -SearchString $userName -ErrorAction SilentlyContinue
                if ($null -ne $user)
                {
                    $AssignmentsValue += $user.ObjectId
                }
            }
            catch
            {
                Write-Verbose -Message "Couldn't get user {$UserName}"
            }
        }
        $task.Assignments = $AssignmentsValue
    }
    #endregion

    #region Attachments
    if ($Attachments.Length -gt 0)
    {
        $attachmentsArray = @()
        foreach ($attachment in $Attachments)
        {
            $attachmentsValue = @{
                Uri   = $attachment.Uri
                Alias = $attachment.Alias
                Type  = $attachment.Type
            }
            $attachmentsArray +=$AttachmentsValue
        }
        $task.Attachments = $attachmentsArray
    }
    #endregion

    #region Categories
    if ($Categories.Length -gt 0)
    {
        $CategoriesValue = @()
        foreach ($category in $Categories)
        {
            $CategoriesValue += $category
        }
        $task.Categories = $CategoriesValue
    }
    #endregion

    #region Checklist
    if ($Checklist.Length -gt 0)
    {
        $checklistArray = @()
        foreach ($checkListItem in $Checklist)
        {
            $checklistItemValue = @{
                Title     = $checkListItem.Title
                Completed = $checkListItem.Completed
            }
            $checklistArray +=$checklistItemValue
        }
        $task.Checklist = $checklistArray
    }
    #endregion

    #region Bucket
    if (-Not [System.String]::IsNullOrEmpty($BucketName))
    {
        [array]$buckets = Get-M365DSCPlannerBucketsFromPlan -GroupId $GroupId `
            -ApplicationId $ApplicationId `
            -GlobalAdminAccount $GlobalAdminAccount `
            -PlanId $PlanId `
            -PlanName $PlanName | Where-Object -FilterScript {$_.Name -eq $BucketName}
        $task.BucketId = $buckets[0].Id
    }
    #endregion

    if ($Ensure -eq 'Present' -and $currentValues.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Planner Task {$Title} doesn't already exist. Creating it."
        $task.Create($GlobalAdminAccount, $ApplicationId)
    }
    elseif ($Ensure -eq 'Present' -and $currentValues.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Planner Task {$Title} already exists, but is not in the `
            Desired State. Updating it."
        Write-Verbose -Message "TASK: $($task | Out-String)"
        $task.Update($GlobalAdminAccount, $ApplicationId)

    }
    elseif ($Ensure -eq 'Absent' -and $currentValues.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Planner Task {$Title} exists, but is should not. `
            Removing it."
        $task.Delete($GlobalAdminAccount, $ApplicationId, $TaskId)
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
        $PlanName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        [Parameter()]
        [System.String[]]
        $AssignedUsers,

        [Parameter()]
        [System.String]
        $Notes,

        [Parameter()]
        [System.String]
        $BucketName,

        [Parameter()]
        [System.String]
        $StartDateTime,

        [Parameter()]
        [System.String]
        $CompletedDateTime,

        [Parameter()]
        [System.String]
        $DueDateTime,

        [Parameter()]
        [System.String[]]
        $Categories,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Attachments,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Checklist,

        [Parameter()]
        [ValidateRange(0, 100)]
        [System.Uint32]
        $PercentComplete,

        [Parameter()]
        [ValidateRange(0, 10)]
        [System.UInt32]
        $Priority,

        [Parameter()]
        [ValidateSet("automatic", "description", "noPreview", "reference", "checklist")]
        [System.String]
        $PreviewType,

        [Parameter()]
        [System.String]
        $ConversationThreadId,

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

    Write-Verbose -Message "Testing configuration of Planner Task {$Title}"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = $PSBoundParameters
    $ValuesToCheck.Remove('ApplicationId') | Out-Null
    $ValuesToCheck.Remove('GlobalAdminAccount') | Out-Null

    # Update Nik
    $ValuesToCheck.Remove("ApplicationId") | Out-Null
    $ValuesToCheck.Remove("TaskId") | Out-Null

    # If the Task is currently assigned to a bucket and the Bucket property is null,
    # assume that we are trying to remove the given task from the bucket and therefore
    # treat this as a drift.
    if ([System.String]::IsNullOrEmpty($Bucket) -and `
        -not [System.String]::IsNullOrEmpty($CurrentValues.Bucket))
    {
        $TestResult = $false
    }
    else
    {
        $ValuesToCheck.Remove("Checklist") | Out-Null
        if (-not (Test-M365DSCPlannerTaskCheckListValues -CurrentValues $CurrentValues `
            -DesiredValues $ValuesToCheck))
        {
            return $false
        }
        $TestResult = Test-Microsoft365DSCParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck $ValuesToCheck.Keys
    }

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
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.Int32]
        $Start,

        [Parameter()]
        [System.Int32]
        $End
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
    $BucketModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\MSFT_PlannerBucket\MSFT_PlannerBucket.psm1' #Custom
    $TaskModulePath = Join-Path $PSScriptRoot -ChildPath 'MSFT_PlannerTask.psm1' #Custom
    $PlanModulePath = Join-Path $PSScriptRoot -ChildPath '..\MSFT_PlannerPlan\MSFT_PlannerPlan.psm1' #Custom
    $content = ''
    for ($i = $Start; $i -le $groups.Length -and $i -le $end; $i++)
    {
        $group = $groups[$i-1]
        $Total = $end
        if ($end -gt $groups.Length)
        {
            $total = $groups.Length
        }
        Write-Information "    (GROUP)[$i/$($total)] $($group.DisplayName) - {$($group.ObjectID)}"
        try
        {
            [Array]$plans = Get-M365DSCPlannerPlansFromGroup -GroupId $group.ObjectId `
                                -GlobalAdminAccount $GlobalAdminAccount `
                                -ApplicationId $ApplicationId

            $j = 1
            foreach ($plan in $plans)
            {
                Write-Information "        (PLAN)[$j/$($plans.Length)] $($plan.Title)"

                [Array]$tasks = Get-M365DSCPlannerTasksFromPlanExport -PlanId $plan.Id `
                                    -GlobalAdminAccount $GlobalAdminAccount `
                                    -ApplicationId $ApplicationId

                #region PlannerPlan
                $params = @{
                    Title              = $plan.Title
                    PlanId             = $plan.Id
                    OwnerGroup         = $group.ObjectId
                    ApplicationId      = $ApplicationId
                    GlobalAdminAccount = $GlobalAdminAccount
                }
                Import-Module $PlanModulePath -Force | Out-Null
                $result = Get-TargetResource @params
                $result.GlobalAdminAccount = Resolve-Credentials -UserName "globaladmin"
                $result.Title = $result.Title.Replace('“', "`"").Replace('”', "`"").Replace("’", "'")
                $content += "        PlannerPlan " + (New-GUID).ToString() + "`r`n"
                $content += "        {`r`n"
                $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock `
                        -ParameterName "GlobalAdminAccount"
                $content += $currentDSCBlock
                $content += "        }`r`n"
                #endregion

                #region Bucket
                $buckets = Get-M365DSCPlannerBucketsFromPlan -PlanName $plan.Title `
                               -GroupId $group.ObjectId `
                               -PlanId $plan.Id `
                               -ApplicationId $ApplicationId `
                               -GlobalAdminAccount $GlobalAdminAccount
                $b = 1
                foreach ($bucket in $buckets)
                {
                    Write-Information "            (BUCKET)[$b/$($buckets.Length)] $($bucket.Name)"
                    $params = @{
                        Name               = $bucket.Name
                        PlanId             = $plan.Id
                        BucketId           = $bucket.Id
                        PlanName           = $plan.Title
                        GroupId            = $Group.ObjectId
                        ApplicationId      = $ApplicationId
                        GlobalAdminAccount = $GlobalAdminAccount
                    }
                    Import-Module $BucketModulePath -Force | Out-Null
                    $result = Get-TargetResource @params
                    $result.GlobalAdminAccount = Resolve-Credentials -UserName "globaladmin"
                    $result.PlanName = $result.PlanName.Replace('“', "`"").Replace('”', "`"").Replace("’", "'")
                    $result.Name = $result.Name.Replace('“', "`"").Replace('”', "`"").Replace("’", "'")
                    $content += "        PlannerBucket " + (New-GUID).ToString() + "`r`n"
                    $content += "        {`r`n"
                    $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
                    $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock `
                        -ParameterName "GlobalAdminAccount"
                    $content += $currentDSCBlock
                    $content += "        }`r`n"
                    $b++
                }
                #endregion
                $k = 1
                foreach ($task in $tasks)
                {
                    Import-Module $TaskModulePath -Force | Out-Null
                    Write-Information "            (TASK)[$k/$($tasks.Length)] $($task.Title)"
                    $params = @{
                        GroupId            = $group.ObjectId
                        TaskId             = $task.Id
                        PlanName           = $plan.Title
                        Title              = $task.Title
                        ApplicationId      = $ApplicationId
                        GlobalAdminAccount = $GlobalAdminAccount
                    }

                    $result = Get-TargetResource @params
                    $result.PlanName = $result.PlanName.Replace('“', "`"").Replace('”', "`"").Replace("’", "'")
                    $result.BucketName = $result.BucketName.Replace('“', "`"").Replace('”', "`"").Replace("’", "'")
                    $result.Title = $result.Title.Replace('“', "`"").Replace('”', "`"").Replace("’", "'")
                    if ([System.String]::IsNullOrEmpty($result.ApplicationId))
                    {
                        $result.Remove("ApplicationId") | Out-Null
                    }
                    if ($result.AssignedUsers.Count -eq 0)
                    {
                        $result.Remove("AssignedUsers") | Out-Null
                    }
                    $result.GlobalAdminAccount = Resolve-Credentials -UserName "globaladmin"
                    if ($result.Attachments.Length -gt 0)
                    {
                        $result.Attachments = [Array](Convert-M365DSCPlannerTaskAssignmentToCIMArray `
                            -Attachments $result.Attachments)
                    }
                    else
                    {
                        $result.Remove("Attachments") | Out-Null
                    }

                    if ($result.Checklist.Length -gt 0)
                    {
                        $result.Checklist = [Array](Convert-M365DSCPlannerTaskChecklistToCIMArray `
                            -Checklist $result.Checklist)
                    }
                    else
                    {
                        $result.Remove("Checklist") | Out-Null
                    }
                    $result.Notes = $result.Notes.Replace('“', "`"").Replace('”', "`"").Replace("’", "'")

                    $content += "        PlannerTask " + (New-GUID).ToString() + "`r`n"
                    $content += "        {`r`n"
                    $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
                    $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock `
                        -ParameterName "GlobalAdminAccount"
                    if ($result.Attachments.Length -gt 0)
                    {
                        try
                        {
                            $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock `
                                -ParameterName "Attachments" `
                                -IsCIMArray $true
                        }
                        catch
                        {
                            Write-Verbose -Message $_
                        }
                    }
                    if ($result.Checklist.Length -gt 0)
                    {
                        $result.CheckList = $result.CheckList.Replace("’", "''").Replace('”', '"').Replace('“', '"')
                        try
                        {
                            $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock `
                                -ParameterName "Checklist" `
                                -IsCIMArray $true
                        }
                        catch
                        {
                            Write-Host -Message $_
                        }
                    }
                    $content += $currentDSCBlock
                    $content += "        }`r`n"
                    $k++
                }
                $j++
            }
        }
        catch
        {
            Write-Host $_
        }
    }
    return $content
}

function Test-M365DSCPlannerTaskCheckListValues
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Collections.HashTable[]]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [System.Collections.HashTable[]]
        $DesiredValues
    )

    # Check in CurrentValues for item that don't exist or are different in
    # the DesiredValues;
    foreach ($checklistItem in $CurrentValues)
    {
        $equivalentItemInDesired = $DesiredValues | Where-Object -FilterScript {$_.Title -eq $checklistItem.Title}
        if ($null -eq $equivalentItemInDesired -or `
            $checklistItem.Completed -ne $equivalentItemInDesired.Completed)
        {
            return $false
        }
    }

    # Do the opposite, check in DesiredValue for item that don't exist or are different in
    # the CurrentValues;
    foreach ($checklistItem in $DesiredValues)
    {
        $equivalentItemInCurrent = $CurrentValues | Where-Object -FilterScript {$_.Title -eq $checklistItem.Title}
        if ($null -eq $equivalentItemInCurrent -or `
            $checklistItem.Completed -ne $equivalentItemInCurrent.Completed)
        {
            return $false
        }
    }
    return $true
}

function Convert-M365DSCPlannerTaskAssignmentToCIMArray
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Collections.HashTable[]]
        $Attachments
    )

    $result = @()
    foreach ($attachment in $Attachments)
    {
        $stringContent = "MSFT_PlannerTaskAttachment`r`n            {`r`n"
        $stringContent += "                Uri = '$($attachment.Uri)'`r`n"
        $stringContent += "                Alias = '$($attachment.Alias.Replace("'", "''"))'`r`n"
        $stringContent += "                Type = '$($attachment.Type)'`r`n"
        $StringContent += "            }`r`n"
        $result += $stringContent
    }
    return $result
}

function Convert-M365DSCPlannerTaskChecklistToCIMArray
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Collections.HashTable[]]
        $Checklist
    )

    $result = @()
    foreach ($checklistItem in $Checklist)
    {
        $stringContent = "MSFT_PlannerTaskChecklistItem`r`n            {`r`n"
        $stringContent += "                Title = '$($checklistItem.Title.Replace("'", "''"))'`r`n"
        $stringContent += "                Completed = `$$($checklistItem.Completed.ToString())`r`n"
        $StringContent += "            }`r`n"
        $result += $stringContent
    }
    return $result
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
    try
    {
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
    catch
    {
        if ($_.Exception -like '*Forbidden*')
        {
            Write-Warning $_.Exception
        }
        else
        {
            Write-Host $_
            Start-Sleep -Seconds 120
            $results = Get-M365DSCPlannerPlansFromGroup -GroupId $GroupId -GlobalAdminAccount $GlobalAdminAccount -ApplicationId $ApplicationId
            return $results
        }
        return ""
    }
}

function Get-M365DSCPlannerBucketNameByTaskId
{
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskId,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationId
    )
    try
    {
        $uri = "https://graph.microsoft.com/v1.0/planner/tasks/$TaskId"
        Write-Verbose -Message "Retrieving BucketId at {$uri}"
        $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method Get
        if ($null -ne $taskResponse.bucketId)
        {
            $bucketID = $taskResponse.bucketId

            $uri = "https://graph.microsoft.com/v1.0/planner/buckets/$bucketID"
            Write-Verbose -Message "BucketID {$bucketId} at {$uri}"
            $bucketResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
                -ApplicationId $ApplicationId `
                -Uri $uri `
                -Method Get
            $bucketName = $bucketResponse.name.Replace("`?", "`"").Replace("`?", "`"")
            return $bucketName
        }
        else
        {
            Write-Verbose -Message "BucketID was null"
            return $null
        }
    }
    catch
    {
        if ($_.Exception -like '*Forbidden*')
        {
            Write-Warning $_.Exception
        }
        else
        {
            Write-Host $_
            Start-Sleep -Seconds 120
            $results = Get-M365DSCPlannerBucketNameByTaskId -TaskId $TaskId -GlobalAdminAccount $GlobalAdminAccount -ApplicationId $ApplicationId
            return $results
        }
        return ""
    }
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
    try
    {
        $results = @()
        $uri = "https://graph.microsoft.com/v1.0/planner/plans/$PlanId/buckets"
        $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method Get
        foreach ($bucket in $taskResponse.value)
        {
            $results += @{
                Name     = $bucket.name
                PlanName = $PlanName
                GroupId  = $GroupId
                Id       = $bucket.id
            }
        }
        return $results
    }
    catch
    {
        if ($_.Exception -like '*Forbidden*')
        {
            Write-Warning $_.Exception
        }
        else
        {
            Write-Host $_
            Start-Sleep -Seconds 120
            $results = Get-M365DSCPlannerBucketsFromPlan -PlanName $PlanName -GroupId $GroupId -PlanId $PlanId -GlobalAdminAccount $GlobalAdminAccount -ApplicationId $ApplicationId
            return $results
        }
        return ""
    }
}

function Get-M365DSCPlannerPlanIdByName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
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
    try
    {
        $uri = "https://graph.microsoft.com/v1.0/groups/$GroupId/planner/plans"
        $planResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method Get
        $PlanId = $null
        foreach ($plan in $planResponse.value)
        {
            if ($plan.title -eq $PlanName)
            {
                $PlanId = $plan.id
                break
            }
        }
        return $PlanId
    }
    catch
    {
        if ($_.Exception -like '*Forbidden*')
        {
            Write-Warning $_.Exception
        }
        else
        {
            Write-Host $_
            Start-Sleep -Seconds 120
            $results = Get-M365DSCPlannerPlanIdByName -PlanName $PlanName -GroupId $GroupId -GlobalAdminAccount $GlobalAdminAccount -ApplicationId $ApplicationId
            return $results
        }
        return ""
    }
}

function Get-M365DSCPlannerTasksFromPlan
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $PlanId,

        [Parameter(Mandatory=$true)]
        [System.String]
        $TaskTitle,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationId
    )
    try
    {
        $results = @()
        $uri = "https://graph.microsoft.com/beta/planner/plans/$PlanId/tasks?`$select=title,id,startDateTime,completedDateTime,dueDateTime,percentComplete"
        $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method Get

        $matchingTasks = @()
        foreach ($taskInfo in $taskResponse.value)
        {
            if ($TaskTitle -eq $taskInfo.title)
            {
                $matchingTasks += @{
                    title = $taskInfo.title
                    id = $taskInfo.id
                    startDateTime = $taskInfo.startDateTime
                    completedDateTime = $taskInfo.completedDateTime
                    dueDateTime = $taskInfo.dueDateTime
                    percentComplete = $taskInfo.percentComplete
                }
            }
        }
        foreach ($task in $matchingTasks)
        {
            $uriDetails = "https://graph.microsoft.com/beta/planner/tasks/$($task.id)/details?`$select=description,checklist"
            $taskDetails = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
                -ApplicationId $ApplicationId `
                -Uri $uriDetails `
                -Method Get

            $startDateTime = $task.startDateTime
            if ($null -eq $startDateTime)
            {
                $startDateTime = ""
            }

            $completedDateTime = $task.completedDateTime
            if ($null -eq $completedDateTime)
            {
                $completedDateTime = ""
            }

            $dueDateTime = $task.dueDateTime
            if ($null -eq $dueDateTime)
            {
                $dueDateTime = ""
            }
            $allCheckListItems = $taskDetails.checklist | gm | Where-Object -FilterScript{$_.MemberType -eq 'NoteProperty'}
            $checkListValue = @()
            foreach ($item in $allCheckListItems)
            {
                $checkListValue += @{
                    Title = $taskDetails.checklist.$($item.Name).title
                    IsChecked = $taskDetails.checklist.$($item.Name).IsChecked
                }
            }
            $results += @{
                Title             = $task.title
                Notes             = $taskDetails.description
                PercentComplete   = $task.percentComplete                
                StartDateTime     = $startDateTime
                DueDateTime       = $dueDateTime
                CompletedDateTime = $completedDateTime
                TaskId            = $task.id
                CheckList         = $checkListValue
            }
        }
        return $results
    }
    catch
    {
        if ($_.Exception -like '*Forbidden*')
        {
            Write-Warning $_.Exception
        }
        else
        {
            Write-Host $_
            Start-Sleep -Seconds 120
            $results = Get-M365DSCPlannerTasksFromPlan -PlanId $PlanId -GlobalAdminAccount $GlobalAdminAccount -ApplicationId $ApplicationId
            return $results
        }
        return ""
    }
}

function Get-M365DSCPlannerTasksFromPlanExport
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    Param(
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
    try
    {
        $results = @()
        $uri = "https://graph.microsoft.com/beta/planner/plans/$PlanId/tasks?`$select=title,id,startDateTime,completedDateTime,dueDateTime,percentComplete"
        $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method Get

        $matchingTasks = @()
        foreach ($taskInfo in $taskResponse.value)
        {
            $matchingTasks += @{
                    title = $taskInfo.title
                    id = $taskInfo.id
                    startDateTime = $taskInfo.startDateTime
                    completedDateTime = $taskInfo.completedDateTime
                    dueDateTime = $taskInfo.dueDateTime
                    percentComplete = $taskInfo.percentComplete
            }
        }
        foreach ($task in $matchingTasks)
        {
            $uriDetails = "https://graph.microsoft.com/beta/planner/tasks/$($task.id)/details?`$select=description,checklist"
            $taskDetails = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
                -ApplicationId $ApplicationId `
                -Uri $uriDetails `
                -Method Get

            $startDateTime = $task.startDateTime
            if ($null -eq $startDateTime)
            {
                $startDateTime = ""
            }

            $completedDateTime = $task.completedDateTime
            if ($null -eq $completedDateTime)
            {
                $completedDateTime = ""
            }

            $dueDateTime = $task.dueDateTime
            if ($null -eq $dueDateTime)
            {
                $dueDateTime = ""
            }
            $allCheckListItems = $taskDetails.checklist | gm | Where-Object -FilterScript{$_.MemberType -eq 'NoteProperty'}
            $checkListValue = @()
            foreach ($item in $allCheckListItems)
            {
                $checkListValue += @{
                    Title = $taskDetails.checklist.$($item.Name).title
                    IsChecked = $taskDetails.checklist.$($item.Name).IsChecked
                }
            }
            $results += @{
                Title             = $task.title
                Notes             = $taskDetails.description
                PercentComplete   = $task.percentComplete                
                StartDateTime     = $startDateTime
                DueDateTime       = $dueDateTime
                CompletedDateTime = $completedDateTime
                TaskId            = $task.id
                CheckList         = $checkListValue
            }
        }
        return $results
    }
    catch
    {
        if ($_.Exception -like '*Forbidden*')
        {
            Write-Warning $_.Exception
        }
        else
        {
            Write-Host $_
            Start-Sleep -Seconds 120
            $results = Get-M365DSCPlannerTasksFromPlan -PlanId $PlanId -GlobalAdminAccount $GlobalAdminAccount -ApplicationId $ApplicationId
            return $results
        }
        return ""
    }
}

Export-ModuleMember -Function *
