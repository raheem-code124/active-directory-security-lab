# SYNTHETIC, OFFLINE ONLY: exercises provisioning with a mock AD module.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root 'scripts/Invoke-LabEmployeeProvisioning.ps1'
$csv = Join-Path $PSScriptRoot 'sample-employees.csv'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("mock-ad-" + [guid]::NewGuid().ToString('N'))
$moduleDir = Join-Path $tmp 'ActiveDirectory'
$log = Join-Path $tmp 'writes.log'
$originalPath = $env:PSModulePath
$originalCase = $env:MOCK_CASE
$originalLog = $env:MOCK_LOG
$moduleCode = @'
function Get-ADDomain {
    [CmdletBinding()]param()
    [pscustomobject]@{DNSRoot=$(if($env:MOCK_CASE -eq 'domain'){'other.example.test'}else{'corp.example.test'})}
}
function Get-ADOrganizationalUnit {
    [CmdletBinding()]param([string]$Identity)
    if($env:MOCK_CASE -eq 'ou' -and $Identity -like 'OU=HR,*'){throw 'Mock missing OU'}
    [pscustomobject]@{DistinguishedName=$Identity}
}
function Get-ADGroup {
    [CmdletBinding()]param([string]$Identity)
    if($env:MOCK_CASE -eq 'group' -and $Identity -eq 'SG_HR_Users'){throw 'Mock missing group'}
    [pscustomobject]@{Name=$Identity}
}
function Get-ADUser {
    [CmdletBinding()]param([string]$Filter,[string[]]$Properties)
    if($env:MOCK_CASE -eq 'wrong_ou' -and $Filter -match 'demo.it01'){
        [pscustomobject]@{DistinguishedName='CN=Demo,OU=Other,DC=corp,DC=example,DC=test'}
    }
    if($env:MOCK_CASE -eq 'repair' -and $Filter -match 'demo.it01'){
        [pscustomobject]@{DistinguishedName='CN=Demo,OU=IT,OU=Company,DC=corp,DC=example,DC=test'}
    }
}
function Get-ADPrincipalGroupMembership {
    [CmdletBinding()]param($Identity)
}
function New-ADUser {
    [CmdletBinding()]param(
       [string]$Name,[string]$GivenName,[string]$Surname,
       [string]$SamAccountName,[string]$UserPrincipalName,
       [string]$Path,[bool]$Enabled,[string]$Description)
    if($Enabled){throw 'Mock rejected an enabled account'}
    Add-Content -LiteralPath $env:MOCK_LOG -Value ("NEW:" + $SamAccountName)
}
function Add-ADGroupMember {
    [CmdletBinding()]param([string]$Identity,[string]$Members)
    if($env:MOCK_CASE -eq 'partial'){throw 'Mock group assignment failure'}
    Add-Content -LiteralPath $env:MOCK_LOG -Value ("GROUP:" + $Members)
}
Export-ModuleMember -Function *
'@
function Assert-Case {
    param([string]$Name,[string]$Scenario,[bool]$Apply=$false,
          [bool]$WhatIf=$false,[string]$ExpectedError='',
          [int]$Creates=0,[int]$Groups=0,[string]$Plan='')
    $env:MOCK_CASE=$Scenario
    if(Test-Path $log){Remove-Item -LiteralPath $log -Force}
    $arguments = @{CsvPath=$csv}
    if($Apply){$arguments.Apply=$true;$arguments.Confirm=$false}
    if($WhatIf){$arguments.WhatIf=$true}
    $errorText=''
    $output=''
    try {$output=(& $target @arguments | Out-String)}catch{$errorText=$_.Exception.Message}
    if($ExpectedError){
        if($errorText -notlike "*$ExpectedError*"){throw "$Name expected '$ExpectedError', got '$errorText'"}
    }elseif($errorText){throw "$Name unexpected error: $errorText"}
    if($Plan -and $output -notlike "*$Plan*"){throw "$Name missing plan action: $Plan"}
    $writes=@(if(Test-Path $log){Get-Content -LiteralPath $log})
    $nc=@($writes|Where-Object {$_ -like 'NEW:*'}).Count
    $ng=@($writes|Where-Object {$_ -like 'GROUP:*'}).Count
    if($nc -ne $Creates -or $ng -ne $Groups){
        throw "$Name mock writes $nc/$ng; expected $Creates/$Groups"
    }
    Write-Host "PASS: mocked AD $Name"
}
try{
    New-Item -Path $moduleDir -ItemType Directory -Force|Out-Null
    $moduleFile=Join-Path $moduleDir 'ActiveDirectory.psm1'
    Set-Content -LiteralPath $moduleFile -Value $moduleCode -Encoding utf8
    $env:PSModulePath="$tmp$([IO.Path]::PathSeparator)$originalPath"
    $env:MOCK_LOG=$log
    Remove-Module ActiveDirectory -ErrorAction SilentlyContinue
    Import-Module $moduleFile -Force -ErrorAction Stop
    if((Get-Module ActiveDirectory).Path -ne $moduleFile){
        throw 'Safety stop: the mock AD module did not load'
    }
    Assert-Case -Name 'plan mode makes no changes' -Scenario normal -Plan 'CREATE_DISABLED_AND_ADD_GROUP'
    Assert-Case -Name 'WhatIf makes no changes' -Scenario normal -Apply $true -WhatIf $true
    Assert-Case -Name 'incorrect domain blocks changes' -Scenario domain -ExpectedError 'Safety stop'
    Assert-Case -Name 'missing OU blocks changes' -Scenario ou -ExpectedError 'Mock missing OU'
    Assert-Case -Name 'missing group blocks changes' -Scenario group -ExpectedError 'Mock missing group'
    Assert-Case -Name 'wrong OU blocks changes' -Scenario wrong_ou -ExpectedError 'outside expected OU'
    Assert-Case -Name 'new users always disabled' -Scenario normal -Apply $true -Creates 4 -Groups 4
    Assert-Case -Name 'partial group failure surfaces' -Scenario partial -Apply $true -ExpectedError 'Mock group assignment failure' -Creates 1
    Assert-Case -Name 'rerun plans missing membership' -Scenario repair -Plan 'ADD_MISSING_GROUP'
    Assert-Case -Name 'rerun repairs membership' -Scenario repair -Apply $true -Creates 3 -Groups 4
    Write-Host 'PASS: ten mocked provisioning safety tests; no live AD accessed.'
}finally{
    Remove-Module ActiveDirectory -ErrorAction SilentlyContinue
    $env:PSModulePath=$originalPath
    $env:MOCK_CASE=$originalCase
    $env:MOCK_LOG=$originalLog
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
