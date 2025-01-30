Function Invoke-SharpPSPublish {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string]$SolutionPath,
        [string[]]$Projects,
        [string]$PublishUrl,
        [string]$MSBuildPath,
        [string[]]$SolutionTargets = @("Restore", "Rebuild"),
        [string]$ProjectExt = "*.csproj",
        [string]$Configuration = "Debug",
        [ValidateSet('Quiet', 'Normal', 'Minimal', 'Detailed', 'Diagnostic')][string]$Verbosity="minimal",
        [string]$Platform="AnyCpu"
    )
    $verbose = ($VerbosePreference -eq "Continue")
    
    $CustomArgs = "-noWarn:MSB3277;MSB3247;CS0168;CS0618;CS2002"
    function Build {
        param (
            [string]$solutionPath
        )
        $properties = @{
            Configuration = $Configuration
        }
        Invoke-SharpPSBuild -Verbose:$verbose -Build $MSBuildPath -Path $SolutionPath -Targets $SolutionTargets -Verbosity $Verbosity -CustomArguments $CustomArgs -Properties $properties
    }
    
    function PublishProject {
        param (
            [string]$projectPath
        )
        $properties = @{
            Platform= $Platform
            Configuration= $Configuration
            PublishUrl= $PublishUrl
            DeployOnBuild= "true"
            DeployDefaultTarget= "WebPublish"
            WebPublishMethod= "FileSystem"
            BuildProjectReferences= "false"
            DeleteExistingFiles= "false"
            SkipBuild="true"
        }
        Invoke-SharpPSBuild -Verbose:$verbose -Build $MSBuildPath -Path $projectPath -Targets Build -Verbosity $Verbosity -CustomArguments $CustomArgs -Properties $properties
    }
    
    Write-Verbose "Build Solution $SolutionPath"
    Build -solutionPath $SolutionPath

    if (-not [string]::IsNullOrEmpty($PublishUrl)) {
        foreach ($projectDir in $Projects) {
             
             $projectPaths = Get-ChildItem -Path $projectDir -Recurse -Filter $ProjectExt -File
             foreach ($item in $projectPaths) {
                Write-Verbose "Publish Project $($item.FullName)"
                PublishProject -projectPath $item.FullName
             }
         }
     }
}
