<#
New Class Valuation Employee (Onboarding) script by Omar Yacoub
Version : 1.0
Date: 07/06/2022
#>

$Path = 'C:\PS\Employee Management'
. $Path\Connect-O365Services.ps1
. $Path\Replicate-allDomainControllers.ps1

function New-classEmployee {
    param(
        [Parameter(Mandatory=$true)]
        [String]$FirstName,
        [Parameter(Mandatory=$true)]
        [String]$LastName,
        [String]$SamAccountName = "$($FirstName.Substring(0,1).ToLower())$($LastName.ToLower())",
        [String]$UserPrincipalName = "$($SamAccountName)@classvaluation.com",
        [Parameter(Mandatory=$true)]
        [ValidateSet("None","Microsoft 365 E3")]
        [String]$License,
        [Parameter(Mandatory=$true)]
        [ValidateSet("","Metro West")]
        [String]$Description,
        [Parameter(Mandatory=$true)]
        [String]$Password
        )
    Connect-O365Services -exchangeOnline -msOnline
    #Determine which license was selected
    switch ($License) {
        "Microsoft 365 E3" {$LicenseName = 'reseller-account:SPE_E3'}
    }

    if ((Get-MsolAccountSku | where {$_.AccountSkuID -eq $LicenseName}).ActiveUnits -eq (Get-MsolAccountSku | where {$_.AccountSkuID -eq $LicenseName}).ConsumedUnits -and $License -ne "None") {
        Write-Host "There are not enough $License licenses available!" -ForegroundColor Red
        Continue
    }

    # Validate SamAccountName length
    if ( $SamAccountName.Length -gt 20 ) { throw "User name $($SamAccountName) too long." }

    # Validate SamAccountName and UserPrincipalName Available
    $count =0
    do {
    $TestAdObject = Get-ADObject -LDAPFilter "(sAMAccountName=$($SamAccountName))"
    if ($TestAdObject -ne $null)
    # { throw "User name $($SamAccountName) already exists." }
    {
        if ($count -eq 0) {$SamAccountName += "00"}
        $SamAccountName = $SamAccountName.Substring(0,$SamAccountName.Length-2)
        $count ++
        $SamAccountName = $SamAccountName + "0" + $count
        $userPrincipalName = "$($SamAccountName)@classvaluation.com"
    }

    } until($TestAdObject -eq $null)
    
    # Validate Department OU
    #$DepartmentOU = Get-ADOrganizationalUnit -SearchBase "OU=Galco,OU=Department Users,DC=galco,DC=com" -LDAPFilter "(name=$($Department))" -SearchScope OneLevel
    #if ( $DepartmentOU -eq $null ) { throw "Unable to locate department $($Department) OU." }

    #$DepartmentOU = "OU=AzureConnect,OU=Main Location,DC=classappraisal,DC=local"
    $DepartmentOU = Get-ADOrganizationalUnit -Filter 'Name -like "AzureConnect"'

    # Splat the parameters
    $NewUserParameters = @{

        # Account Tab
        SamAccountName = $SamAccountName;
        UserPrincipalName = $UserPrincipalName;
        Name = "$($FirstName) $($LastName)";
        ChangePasswordAtLogon = $false;
        Description = $Description;

        # General Tab
        GivenName = $FirstName;
        Surname = $LastName;
        DisplayName = "$($FirstName) $($LastName)";
        EmailAddress = $UserPrincipalName

        # Profile Tab
        ScriptPath = "login.bat"
        HomeDrive = "P:";
        HomeDirectory = " \\CADC02\USERHOME\$($SamAccountName)";

        
        # Other Stuff
        AccountPassword = ConvertTo-SecureString $Password -AsPlainText -Force
        Path = $DepartmentOU.DistinguishedName
        PassThru = $true
        Enabled = $true
    }

    New-ADUser @NewUserParameters
    
    # Get-ADuser -Identity $SamAccountName | Set-ADUser -Description $Description
    # Get-ADUser -Properties mailNickname -Identity $SamAccountName | Set-ADUser -Replace @{mailNickname =$SamAccountName}
    # Add-ADGroupMember -Identity $Group -Members $SamAccountName

    #Sync AD accross all DCs.
    Replicate-AllDomainControllers

    write-host "Waiting for $UserPrincipalName to be in O365" -foregroundcolor green
    while ((get-user $userPrincipalName -ErrorAction 'SilentlyContinue') -eq $null) {Start-Sleep -Seconds 10}
    write-host "$UserPrincipalName is in O365" -foregroundcolor green
    Set-User $UserPrincipalName -RemotePowerShellEnabled $false
    if ($License -ne "None") {
        Set-MsolUser -UserPrincipalName $UserPrincipalName -UsageLocation US
        Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses $LicenseName

    }
    Set-MsolUserPassword -UserPrincipalName $UserPrincipalName -NewPassword $Password -ForceChangePassword $false
    #Enable MFA for the New user
    #if($Enable_MFA){
    #$st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    #$st.RelyingParty = "*"
    #$st.State = "Enabled"
    #$sta = @($st)
    #Set-MsolUser -UserPrincipalName $UserPrincipalName -StrongAuthenticationRequirements $sta
    #}

}