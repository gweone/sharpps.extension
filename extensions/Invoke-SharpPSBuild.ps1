Function Invoke-SharpPSBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Targets,
        [string]$Build,
        [hashtable]$Properties,
        [string]$CustomArguments,
        [ValidateSet('Quiet', 'Normal', 'Minimal', 'Detailed', 'Diagnostic')][string]$Verbosity="minimal",
        [string]$VSProduct,
        [string]$VSChannelID
    )
    
    $verbose = ($VerbosePreference -eq "Continue")
    Set-SDK -Verbose:$verbose
    if([string]::IsNullOrEmpty($Build))
    {
        $order = @{
            "Enterprise" = 1
            "Profesional" = 2
            "Comunnity" = 3
            "BuildTools" = 4
        }
        $VSPath = Get-VisualStudioInstance -Verbose:$verbose | Where-Object { $_.ChannelId -like '*Release' } | Where-Object {
            if(-not [string]::IsNullOrEmpty($VSProduct) -and -not [string]::IsNullOrEmpty($VSChannelID)){
                return $_.ProductId -like "*$($VSProduct)" -and $_.ChannelId -like "*$($VSChannelID)*"
            }
            elseif (-not [string]::IsNullOrEmpty($VSProduct)) {
                return $_.ProductId -like "*$($VSProduct)"
            }elseif (-not [string]::IsNullOrEmpty($VSChannelID)) {
                return $_.ChannelId -like "*$($VSChannelID)*"
            }
            return $_.ChannelId -like "*Release"
        } | Sort-Object InstallationVersion -Descending | Sort-Object {
            foreach ($key in $order.Keys) {
                if ($_.ProductId -match "Microsoft\.VisualStudio\.Product\.$key") {
                    return $order[$key]
                }
            }
            return [int]::MaxValue
        } | Select-Object -ExpandProperty InstallationPath -First 1
        if(-not $VSPath){
            Throw "Visual Studio not installed or require release channel"
        }
        $Build = Join-Path $VSPath -ChildPath "MSBuild\Current\Bin\msbuild.exe"
    }
    $BuildArgs = @($Path);
    $BuildArgs += "/target:" + ($Targets -join ';')
    $BuildArgs += "/verbosity:" + $Verbosity
    if($Properties)
    {
        $Properties.GetEnumerator() | ForEach-Object {
            $BuildArgs += "/property:" + $_.Key + "=" + $_.Value
        }
    }
    $BuildArgs += $CustomArguments
    Write-Verbose "Executing MSbuild... `n$Build $BuildArgs"
    & $Build $BuildArgs
    if($LASTEXITCODE -eq 1 -and $ErrorActionPreference -eq "Stop")
    {
        Throw "Build failed"
    }
}