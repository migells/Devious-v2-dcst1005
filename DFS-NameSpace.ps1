Invoke-Command -ComputerName srv1 -ScriptBlock {
    Install-WindowsFeature -Name FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con
}

# verify instalation

Invoke-Command -ComputerName srv1 -ScriptBlock {
    Get-WindowsFeature | Where-Object {$_.Name -in ('FS-DFS-Namespace','FS-DFS-Replication','RSAT-DFS-Mgmt-Con')}
}

# create main directories

Invoke-Command -ComputerName srv1 -ScriptBlock {
    New-Item -Path "C:\dfsroots" -ItemType Directory -Force
    New-Item -Path "C:\shares" -ItemType Directory -Force
    
    # Create department folders
    $departments = @('Finance','Sales','IT','Consultants','HR')
    foreach ($dept in $departments) {
        New-Item -Path "C:\shares\$dept" -ItemType Directory -Force
    }
    
    # Create files folder under dfsroots
    New-Item -Path "C:\dfsroots\files" -ItemType Directory -Force
}

#Create SMB shares for all folders with Everyone having Full Access:

Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Share department folders
    $departments = @('Finance','Sales','IT','Consultants','HR')
    foreach ($dept in $departments) {
        New-SmbShare -Name $dept -Path "C:\shares\$dept" -FullAccess "Everyone"
    }
    
    # Share DFS root folder
    New-SmbShare -Name "files" -Path "C:\dfsroots\files" -FullAccess "Everyone"
}

#Create DFS Namespace Root

Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Create new DFS namespace
    New-DfsnRoot -TargetPath "\\srv1\files" `
                 -Path "\\Devious.sec\files" `
                 -Type DomainV2 `
                 -GrantAdminAccounts "Devious\Domain Admins"
}

# Create DFS Folders (Links)

Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Create DFS folders for each department
    $departments = @('Finance','Sales','IT','Consultants','HR')
    foreach ($dept in $departments) {
        New-DfsnFolder -Path "\\Devious.sec\files\$dept" `
                      -TargetPath "\\srv1\$dept" `
                      -EnableTargetFailback $true
    }
}

# Verify DFS Namespace and Folders

Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Verify DFS root
    Get-DfsnRoot -Path "\\Devious.sec\files"

    # Verify DFS folders
    Get-DfsnFolder -Path "\\Devious.sec\files\*" | 
    Format-Table Path,TargetPath,State -AutoSize
}


# Configuring NTFS Permissions

Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Configure NTFS permissions for each department
    $folderPermissions = @{
        'HR' = 'l_fullAccess-hr-share'
        'IT' = 'l_fullAccess-it-share'
        'Sales' = 'l_fullAccess-sales-share'
        'Finance' = 'l_fullAccess-finance-share'
        'Consultants' = 'l_fullAccess-consultants-share'
    }

    foreach ($folder in $folderPermissions.Keys) {
        $path = "C:\shares\$folder"
        $group = $folderPermissions[$folder]

        # Create new ACL
        $acl = New-Object System.Security.AccessControl.DirectorySecurity

        # Disable inheritance and remove inherited permissions
        $acl.SetAccessRuleProtection($true, $false)
        
        # Create and add the rules
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $groupRule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")

        $acl.AddAccessRule($adminRule)
        $acl.AddAccessRule($systemRule)
        $acl.AddAccessRule($groupRule)

        # Apply the new ACL
        Set-Acl -Path $path -AclObject $acl
        Write-Host "Permissions set for $folder"
    }

    # Configure DFS root with same approach
    $dfsPath = "C:\dfsroots\files"
    $dfsAcl = New-Object System.Security.AccessControl.DirectorySecurity
    $dfsAcl.SetAccessRuleProtection($true, $false)

    # Add base permissions
    $dfsAcl.AddAccessRule($adminRule)
    $dfsAcl.AddAccessRule($systemRule)

    # Add all department groups
    foreach ($group in $folderPermissions.Values) {
        $groupRule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $dfsAcl.AddAccessRule($groupRule)
    }

    Set-Acl -Path $dfsPath -AclObject $dfsAcl
    Write-Host "Permissions set for DFS root"
}


# Verify ntfs permissions

Invoke-Command -ComputerName srv1 -ScriptBlock {
    $folders = @('HR', 'IT', 'Sales', 'Finance', 'Consultants')
    foreach ($folder in $folders) {
        Write-Host "`nPermissions for $folder folder:" -ForegroundColor Yellow
        (Get-Acl -Path "C:\shares\$folder").Access | Format-Table IdentityReference,FileSystemRights
    }

    Write-Host "`nPermissions for DFS root:" -ForegroundColor Yellow
    (Get-Acl -Path "C:\dfsroots\files").Access | Format-Table IdentityReference,FileSystemRights
}

