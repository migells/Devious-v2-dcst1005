# Define your groups with their properties
$groups = @(
    @{
        Name = "l_fullAccess-hr-share"
        Path = "OU=Local,OU=Devious_Groups,DC=Devious,DC=sec"
        Scope = "DomainLocal"
        Category = "Security"
    },
    @{
        Name = "l_fullAccess-it-share"
        Path = "OU=Local,OU=Devious_Groups,DC=Devious,DC=sec"
        Scope = "DomainLocal"
        Category = "Security"
    },
    @{
        Name = "l_fullAccess-sales-share"
        Path = "OU=Local,OU=Devious_Groups,DC=Devious,DC=sec"
        Scope = "DomainLocal"
        Category = "Security"
    },
    @{
        Name = "l_fullAccess-finance-share"
        Path = "OU=Local,OU=Devious_Groups,DC=Devious,DC=sec"
        Scope = "DomainLocal"
        Category = "Security"
    },
    @{
        Name = "l_fullAccess-consultants-share"
        Path = "OU=Local,OU=Devious_Groups,DC=Devious,DC=sec"
        Scope = "DomainLocal"
        Category = "Security"
    }
)

# Function to create a group with error handling
function New-CustomADGroup {
    param (
        [string]$Name,
        [string]$Path,
        [string]$Scope,
        [string]$Category
    )
    try {
        # Check if the group already exists in the specified OU
        $existingGroup = Get-ADGroup -Filter "Name -eq '$Name'" -SearchBase $Path -ErrorAction SilentlyContinue
        
        if ($existingGroup) {
            Write-Host "⚠️ Group '$Name' already exists in $Path." -ForegroundColor Yellow
        } else {
            New-ADGroup -Name $Name -Path $Path -GroupScope $Scope -GroupCategory $Category -ErrorAction Stop
            Write-Host "✅ Successfully created group: '$Name'." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Error creating group '$Name': $_" -ForegroundColor Red
    }
}

# Iterate over each group and create it
foreach ($group in $groups) {
    New-CustomADGroup -Name $group.Name -Path $group.Path -Scope $group.Scope -Category $group.Category
}
