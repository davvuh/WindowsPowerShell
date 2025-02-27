<#
.SYNOPSIS
Scan all sub-folders looking for Git repos and fetch/pull each of them to
get latest code.

.PARAMETER Branch
Speciies the branch name, default is read from the .git\config file

.PARAMETER Project
Specifies the project (subfolder) to update. If not specified then it will
scan all subfolders and update every one that contains a .git folder. 

.PARAMETER Reset
Perform a hard reset to the tip of the specified Branch 
for each repo before fetch and pull. This is to discard all local changes.
#>

param (
	[Parameter(Position=0)] [string] $Project,
	[Parameter(Position=1)] [string] $Branch,
	[switch] $Reset
)

Begin
{
	$script:divider = New-Object String('-', 80)


    function Update
    {
        param (
            [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
            [string] $Project
        )

        Push-Location $Project

        $br = $branch
        if (!$Branch)
        {
            $br = ReadBranch
        }

        $updated = (git log -1 --date=format:"%b %d, %Y" --format="%ad")

        Write-Host $divider
        Write-Host "... updating $Project from $br, last updated $updated" -ForegroundColor Blue

        if ($Reset)
        {
            # revert uncommitted changes that have been added to the index
            git reset --hard origin/$br
            # revert uncommitted, unindexed changes (f=force, d=recurse, x=uncontrolled)
            git clean -dxf
        }

        git fetch origin
        git pull origin $br

        Pop-Location
    }


    function ReadBranch
    {
        $a = Get-Content .\.git\config | Select-String -Pattern '^\[branch "(.+)"\]$'
        if ($a.Matches.Success)
        {
            return $a.Matches.Groups[1].Value
        }

        return 'main'
    }
}
Process
{
    if ($Project)
    {
        Update $Project
    }
    else
    {
        Get-ChildItem | ? { Test-Path (Join-Path $_.FullName '.git') } | Select -ExpandProperty Name | % { Update $_ }
    }
}
