function Replicate-allDomainControllers {
    Invoke-Command -ComputerName AZEASTSYNC01 {
        #function Replicate-AllDomainController {
        #    (Get-ADDomainController -Filter *).Name | Foreach-Object { repadmin /syncall $_ (Get-ADDomain).DistinguishedName /e /A };
        #}
        #Replicate-AllDomainController
        Start-ADSyncSyncCycle -PolicyType Delta
    }
}