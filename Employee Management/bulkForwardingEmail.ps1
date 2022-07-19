<#
Bulk forwarding emails script by Omar Yacoub
Version : 1.0
Date: 07/18/2022
#>
function bulkForwardingEmails {
    Param (
    [Parameter(Mandatory=$true)]
    [String]$csvPath
    )

    if (!(Test-Path $csvPath)) {
        Write-Host "$($csvPath) is not a valid path!" -ForegroundColor Red
        Continue
    }

    $emailList = import-csv $csvPath

    foreach ($u in $emailList) {
    # Assign a variable name to each column used from the CSV.
    $userEmail = $u.userEmail
    $forwardToEmail = $u.forwardToEmail
    Write-Host "Set forward from $userEmail to $forwardToEmail" -foregroundcolor Yellow
    set-mailbox $userEmail -ForwardingSMTPAddress $forwardToEmail -DeliverToMailboxAndForward $false
    Start-Sleep -Seconds 7
    Write-Host "the forwarding setup is completed!" -foregroundcolor green
    }    
}