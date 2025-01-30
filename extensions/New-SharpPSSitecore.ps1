Function New-SharpPSSitecore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ($_ -match '^[^\s.-]+$') {
                $true
            } else {
                throw "The parameter '$($_)' is invalid. It should not contain spaces, dash or dots."
            }
        })][string]$SolutionName,
        [Parameter(Mandatory = $true)][string]$TargetDirectory,
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$SitecorePath,
        [version]$Version,
        [string]$RepositoryUrl,
        [string]$RepositoryBranch,
        [string]$Area="v1",
        [string]$VSProduct="Enterprise",
        [switch]$IncludeRecommended
    )
    
    $isVerbose = $VerbosePreference -eq "Continue"
    $VSPath = Get-VisualStudioInstance -Verbose:$isVerbose | Where-Object { $_.ProductId -like "*$VSProduct" } | Select-Object -ExpandProperty InstallationPath -First 1
    if(-not $VSPath){
        if(-not $IncludeRecommended){
            Write-Warning "Visual Studio $VSProduct is not installed. Add switch -IncludeRecommended"
            return
        }
        $VSPath = New-SharpPSVisualStudio -Verbose:$isVerbose -VSProduct $VSProduct | Select-Object -ExpandProperty InstallationPath
    }
    $VSPath = Join-Path $VSPath -ChildPath "Common7\IDE\devenv.exe"
    $arguments = @("/Command", "`"NewSharpPS Name=$SolutionName&Destination=$TargetDirectory&Config.Url=$Url&Config.Area=$Area&Config.SitecorePath=$SitecorePath&Repository.Url=$RepositoryUrl&Repository.Branch=$RepositoryBranch&Exit=true`"")
    Write-Host "`nOpening Visual Studio, Please wait until it close automatically" -ForegroundColor Magenta
    $process = Start-Process -FilePath $VSPath -ArgumentList $arguments -PassThru  
    Write-Verbose "Running with id $($process.Id)"
    $process.WaitForExit() 
    $exitCode = $process.ExitCode
    $SolutionDirectory = Join-Path $TargetDirectory -ChildPath $SolutionName
    $SolutionPath = Join-Path $SolutionDirectory -ChildPath "$SolutionName.sln"
    
    if($exitCode -eq 0 -or (Test-Path $SolutionPath)){
        Write-Host "Solution is created at $SolutionDirectory" -ForegroundColor Green
    }
    else{
        Throw "Create Solution is failed"
    }
    
    Invoke-SharpPSGitInit -Verbose:$isVerbose -Path $SolutionDirectory -RepositoryUrl $RepositoryUrl -RepositoryBranch $RepositoryBranch
    Invoke-SharpPSBuild -Verbose:$isVerbose -Path $SolutionPath -Targets Restore -Verbosity Quiet
    Invoke-SharpPSSitecoreSPE -Verbose:$isVerbose -SitecorePath $SitecorePath
}