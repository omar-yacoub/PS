$Path = 'C:\PS'
. $Path\Connect-O365Services.ps1
. $Path\Replicate-allDomainControllers.ps1

function Remove-classEmployee {
    <#
    Requires SharePoint Online Management Shell to be installed. (Install-Module -Name Microsoft.Online.SharePoint.PowerShell)
    #>
    param (
        [Parameter(Mandatory=$true)]
        [String]$userEmail,
        # [Parameter(Mandatory=$true)]
        # [String]$termDate,
        [Parameter(Mandatory=$false)]
        [String]$forwardToEmail,
        [Parameter(Mandatory=$false)]
        [switch]$removeLicense
    )

    #Verify the sharepoint powershell module is installed and connected.
    Connect-O365Services -exchangeOnline -msOnline -sharepoint

    #Verify that values for userEmail and forwardToEmail are correct.
    if ((Get-ADUser -Filter "userPrincipalName -eq `"$userEmail`"" -Properties *) -eq $null) {
        Write-Host "$userEmail is not valid!" -ForegroundColor Red
        continue
    }
    if ($forwardToEmail -eq $null -or $forwardToEmail -eq '') {
        $forwardToEmail = 'N/A'
    }
    if ($forwardToEmail -ne 'N/A') {
        if ((Get-mailbox -Filter "userPrincipalName -eq `"$forwardToEmail`"") -eq $null) {
            Write-Host "$forwardToEmail is not valid!" -ForegroundColor Red
            Continue
        }
    }

    #Get the user's account info.
    $ADuser = Get-ADUser -Filter "userPrincipalName -eq `"$userEmail`"" -Properties *

    #Change the user's description in AD.
    #Set-ADUser $ADuser.SID -Description "Term: $termDate FWD: $forwardToEmail"
    #Rename-ADObject $ADuser.ObjectGUID -newName ('~'+$ADuser.Name)

    #Remove the user from all groups and distribution lists.
    Write-Host "Removing user from the following groups:" $ADuser.MemberOf
    $ADuser | ForEach-Object {$ADuser.Memberof | Remove-ADGroupMember -Members $ADuser.sid -Confirm:$FALSE}
    $distGroups = Get-DistributionGroup | Where-Object {$_.IsDirSynced -eq $false}
    foreach ($group in $distGroups) {
        if (Get-DistributionGroupMember -Identity $group.id | where {$_.primarysmtpaddress -eq $useremail}) {
            Remove-DistributionGroupMember -Identity $group.id -Member $useremail -Confirm: $false
            Write-Output "$useremail was removed from $($Group.DisplayName)"
        }
    }

    #Disable the user's account.
    Disable-ADAccount $ADuser.SID

    #Move AD object to Disabled Accounts OU
    $targetOU = "OU=Disabled Users,OU=Disabled Accounts,DC=classappraisal,DC=local"
    $ADuser | Move-ADObject -TargetPath $targetOU

    #Remove the mobile device from the user's account.
    Get-EXOMobileDeviceStatistics -UserPrincipalName $userEmail | Remove-MobileDevice -Confirm:$false

    #Forward the user's emails to their manager and give them full access if applicable.
    if ($forwardToEmail -ne 'N/A') {
        set-mailbox $userEmail -ForwardingAddress $forwardToEmail -DeliverToMailboxAndForward $false
    }

    #Change the user's mailbox to a shared mailbox.
    if ($forwardToEmail -ne 'N/A') {
    Set-Mailbox $userEmail -Type shared
    }
    
    #Give the user's manager full access to the shared mailbox if applicable.
    if ($forwardToEmail -ne 'N/A') {
        Add-MailboxPermission -Identity $userEmail -User $forwardToEmail -AccessRights FullAccess
    }

    #Block the user from signing in.
    Set-MsolUser -UserPrincipalName $userEmail -BlockCredential $true

    #If one drive is not in use, remove the user's licenses. Currently disabled because it will return 1 even if the user has not stored any files in OneDrive.
    # $oneDrive = Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Owner -eq $userEmail"
    #if (($oneDrive.StorageUsageCurrent -eq 0 -or $oneDrive -eq $null) -and $removeLicense) {
    if ($removeLicense) {
        foreach ($l in get-msoluser -UserPrincipalName $userEmail) {
            Set-MsolUserLicense -UserPrincipalName $userEmail -RemoveLicenses $l.Licenses.AccountSkuId
        }
    } #else {
       # $oneDriveUse = $true
    #}

    if ($forwardToEmail -eq 'N/A') {
    Remove-MsolUser -UserPrincipalName $userEmail
    }
    #Sync AD accross all DCs.
    Replicate-AllDomainControllers
    
    #if ($oneDriveUse) {Write-Host "Onedrive in use. Not removing license." -ForegroundColor Red}
}

Show-Command Remove-classEmployee
