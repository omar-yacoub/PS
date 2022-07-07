function Connect-O365Services {
    Param (
        [Parameter(Mandatory=$false)]
        [switch]$exchangeOnline,
        [Parameter(Mandatory=$false)]
        [switch]$msOnline,
        [Parameter(Mandatory=$false)]
        [switch]$sharepoint
    )

    if ($exchangeOnline -eq $true) {
        if ((get-InstalledModule ExchangeOnlineManagement) -eq $null) {Install-Module -Name ExchangeOnlineManagement}
        try {
            Get-Mailbox -ErrorAction stop > $null
        }
        catch {
            Connect-ExchangeOnline
        }
    }

    if ($msOnline -eq $true) {
        if ((get-InstalledModule MSOnline) -eq $null) {Install-Module -Name MSOnline}
        try {
            Get-MsolUser -ErrorAction stop > $null
        }
        catch {
            Connect-MsolService
        }
    }

    if ($sharepoint -eq $true) {
        if ((get-InstalledModule Microsoft.Online.SharePoint.PowerShell) -eq $null) {Install-Module -Name Microsoft.Online.SharePoint.PowerShell}
        try {
            Get-SPOSite -ErrorAction stop > $null
        }
        catch {
            Connect-SPOService -url https://classappraisal1-admin.sharepoint.com/
        }
    }
}