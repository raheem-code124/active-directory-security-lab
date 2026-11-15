<#
.SYNOPSIS
  Validate a four-column fictional employee CSV without connecting to AD.
.DESCRIPTION
  NEW reference validation module; not the original Create-Employees-v3.ps1.
  No directory writes. Suitable for offline synthetic tests.
#>
Set-StrictMode -Version Latest
function Import-LabEmployees {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "CSV file does not exist: $Path"
    }
    $rows = @(Import-Csv -LiteralPath $Path)
    if ($rows.Count -eq 0) { throw 'CSV contains no employee rows.' }
    $required = @('FirstName','LastName','Username','Department')
    $actual = @($rows[0].PSObject.Properties.Name)
    foreach ($column in $required) {
        if ($column -notin $actual) { throw "CSV missing required column: $column" }
    }
    $groupMap = @{
        IT='SG_IT_Users'
        HR='SG_HR_Users'
        Finance='SG_Finance_Users'
        Operations='SG_Operations_Users'
    }
    $seen = @{}
    $line = 1
    foreach ($row in $rows) {
        $line++
        $first = ([string]$row.FirstName).Trim()
        $last = ([string]$row.LastName).Trim()
        $username = ([string]$row.Username).Trim()
        $dept = ([string]$row.Department).Trim()
        if ($first -notmatch '^[a-zA-Z][a-zA-Z -]{0,49}$' -or
            $last -notmatch '^[a-zA-Z][a-zA-Z -]{0,49}$') {
            throw "Invalid first or last name on CSV line $line"
        }
        if ($username -notmatch '^[a-z][a-z0-9._-]{1,19}$') {
            throw "Invalid username on CSV line $line; use 2-20 lowercase ASCII characters."
        }
        if (-not $groupMap.ContainsKey($dept)) {
            throw "Invalid department '$dept' on CSV line $line"
        }
        if ($seen.ContainsKey($username)) {
            throw "Duplicate username '$username' on CSV line $line"
        }
        $seen[$username] = $true
        [pscustomobject]@{
            FirstName=$first
            LastName=$last
            Username=$username
            Department=$dept
            Group=$groupMap[$dept]
            OuName=$dept
        }
    }
}
Export-ModuleMember -Function Import-LabEmployees
