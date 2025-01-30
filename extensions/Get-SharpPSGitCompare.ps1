Function Get-SharpPSGitCompare {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$CommitHash
    )

    $current = Get-Content -Path $Path
    $current = $current | ForEach-Object {
        [PSCustomObject]@{ 
            LineNumber = [array]::IndexOf($current, $_) + 1; 
            Text = $_ 
        }
    }

    $older = Get-GitContent -Path $Path -CommitHash $CommitHash
    if(-not $older) {
        $older = @("")
    }
    $older = $older | ForEach-Object{
        [PSCustomObject]@{ 
            LineNumber = [array]::IndexOf($older, $_) + 1; 
            Text = $_ 
        }
    }

    Compare-Object -ReferenceObject $older -DifferenceObject $current -Property Text -PassThru | Group-Object LineNumber | ForEach-Object {
        $x = $_.Group | Select-Object -First 1
        $action = "Add Line"
        if($_.Group.Count -eq 2) {
            $action = "Modify Line"
        }
        elseif($x.SideIndicator -eq "<=") { 
            $action = "Remove Line"
        }
        [PSCustomObject]@{
            FileName = $Path
            Action = $action
            LineNumber = $_.Name
            Text = $x.Text
        }
    }
}