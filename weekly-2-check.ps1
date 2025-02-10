 # Get all Organizational Units (OUs) and their details
 Get-ADOrganizationalUnit -Filter * -Properties CanonicalName | ForEach-Object {
    $ou = $_
    Write-Host "OU: $($ou.Name), Path: $($ou.DistinguishedName)"
    # Get and display user objects in the OU
    Get-ADUser -Filter * -SearchBase $ou.DistinguishedName | ForEach-Object {
        Write-Host "`tUser: $($_.Name)"
    }
    # Get and display group objects in the OU
    Get-ADGroup -Filter * -SearchBase $ou.DistinguishedName | ForEach-Object {
        Write-Host "`tGroup: $($_.Name)"
    }
    Write-Host ""
} 

