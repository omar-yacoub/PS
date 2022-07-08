$Path = 'C:\PS\Employee Management'
. $Path\newClassEmployee.ps1

function BulkNewUsers {
    Param (
    [Parameter(Mandatory=$true)]
    [String]$csvPath
    )

    if (!(Test-Path $csvPath)) {
        Write-Host "$($csvPath) is not a valid path!" -ForegroundColor Red
        Continue
    }

    $userList = import-csv $csvPath

    foreach ($u in $userList) {
    # Assign a variable name to each column used from the CSV.
    $FirstName = $u.FirstName
    $LastName = $u.LastName
    $Description =$u.Description
    $Password =$u.Password
    $License = $u.License 

    New-classEmployee -Description $Description -FirstName $FirstName -LastName $LastName -License $License -Password $Password
    }    
}



