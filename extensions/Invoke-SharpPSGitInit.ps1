FUNCTION Invoke-SharpPSGitInit
{
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string]$Path,
        [string]$RepositoryUrl,
        [string]$RepositoryBranch="main"
    )
    if(Test-Path ".git"){
        Write-Verbose ".git already init"
        return
    }

    if(-not $RepositoryUrl){
        Write-Warning "Repository Url is not define. Skip initialize"
        return
    }

    $isVerbose = $VerbosePreference -eq "Continue"
    Set-Location $Path
    Set-SDK -Verbose:$isVerbose
    Write-Verbose "Initiate git for $Path"
    if(-not (Test-Path README.md)){
        New-Item -Path README.md -ItemType "File" | Out-Null
    }
    git init --initial-branch=$RepositoryBranch
    git add README.md
    git commit -m "Initial commit"
    git remote add origin $RepositoryUrl
    git push
}