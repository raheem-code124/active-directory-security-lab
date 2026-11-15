Import-Module ActiveDirectory -ErrorAction Stop

$employees = @(Import-Csv "C:\ADLab\Scripts\employees.csv")

$groups = @{
    IT         = "SG_IT_Users"
    HR         = "SG_HR_Users"
    Finance    = "SG_Finance_Users"
    Operations = "SG_Operations_Users"
}

if ($employees.Count -ne 28) {
    throw "Expected 28 CSV records."
}

$duplicates = $employees | Group-Object Username |
    Where-Object { $_.Count -gt 1 }

if ($duplicates) {
    throw "Duplicate usernames found in CSV."
}

$invalid = $employees | Where-Object {
    $_.Username -notmatch '^[a-z][a-z0-9]{1,19}$' -or
    -not $groups.ContainsKey($_.Department)
}

if ($invalid) {
    throw "Invalid username or department in CSV."
}

foreach ($e in $employees) {
    $username = $e.Username
    $department = $e.Department
    $group = $groups[$department]

    try {
        $user = Get-ADUser -Filter "SamAccountName -eq '$username'" -Properties Enabled -ErrorAction Stop

        if (-not $user) {
            $temporaryPassword = [guid]::NewGuid().ToString("N") + "Aa9!"
            $securePassword = ConvertTo-SecureString $temporaryPassword -AsPlainText -Force

            New-ADUser -Name "$($e.FirstName) $($e.LastName)" `
                -GivenName $e.FirstName `
                -Surname $e.LastName `
                -SamAccountName $username `
                -UserPrincipalName "$username@corp.example.test" `
                -Path "OU=$department,OU=Company,DC=corp,DC=example,DC=test" `
                -Department $department `
                -AccountPassword $securePassword `
                -Enabled $true `
                -ChangePasswordAtLogon $true `
                -ErrorAction Stop

            $user = Get-ADUser -Identity $username -Properties Enabled -ErrorAction Stop
            Write-Host "CREATED: $username" -ForegroundColor Green
        }

        if (-not $user.Enabled) {
            Write-Warning "DISABLED: $username requires review"
            continue
        }

        $membership = Get-ADGroupMember -Identity $group -ErrorAction Stop |
            Where-Object { $_.SamAccountName -eq $username }

        if (-not $membership) {
            Add-ADGroupMember -Identity $group -Members $username -ErrorAction Stop
            Write-Host "GROUP ASSIGNED: $username -> $group" -ForegroundColor Green
        }
        else {
            Write-Host "VERIFIED: $username -> $group" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "FAILED: $username - $($_.Exception.Message)"
    }
}
