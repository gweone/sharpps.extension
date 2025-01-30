Function New-SharpPSVisualStudio {
    [CmdletBinding()]
    param(
        [string]$VSProduct="Enterprise",
        [string]$VSYear="2022",
        [string]$VSKey="VHF9H-NXBBB-638P6-6JHCY-88JWH",
        [string]$VSUrl="",
        [string]$VsixUrl,
        [switch]$Passive,
        [switch]$SkipRemoveOlderVersion
    )
    
    $isVerbose = $VerbosePreference -eq "Continue"
    $majorVersion = 17
    switch ($VSYear)
    {
        '2019' { $majorVersion = 16 }
        '2022' { $majorVersion = 17 }
        default { throw "Unsupported VisualStudioYear: $VSYear"}
    }
    $ChannelId = 'VisualStudio.{0}.{1}' -f $majorVersion, "Release"
    $VSPackage = "VisualStudio$VSYear$VSProduct".ToLower()
    $visualstudio = Get-VisualStudioInstance -Verbose:$isVerbose | Where-Object { $_.ProductId -like "*$VSProduct" -and $_.ChannelId -eq $ChannelId }
    if(-not $visualstudio)
    {
        if([string]::IsNullOrEmpty($VSUrl))
        {
            $VSUrl = "https://aka.ms/vs/$majorVersion/release/vs_$VSProduct.exe".ToLower()
        }

        $env:ChocolateyIgnoreChecksums='true'
        $env:chocolateyPackageParameters="--add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --includeRecommended --includeOptional --locale en-US"
        if($Passive.IsPresent){
            $env:chocolateyPackageParameters += " --passive"
        }
        Write-Verbose "Install Microsoft Visual Studio $VSProduct $VSYear via $VSUrl"
        Install-VisualStudio -Verbose:$isVerbose `
            -PackageName $VSPackage `
            -ApplicationName "Microsoft Visual Studio $VSProduct $VSYear" `
            -Url $VSUrl `
            -InstallerTechnology 'WillowVS2017OrLater' `
            -Product $VSProduct `
            -VisualStudioYear $VSYear `
            -Preview $false

        $visualstudio = Get-VisualStudioInstance | Where-Object { $_.ProductId -like "*$VSProduct" -and $_.ChannelId -like $ChannelId }

        $MPC = "09660"
        switch ($VSYear)
        {
            '2019' { 
                if($VSProduct -eq "Professional"){                    
                    $MPC = "09260"
                }
                else {                    
                    $MPC = "09262"
                }
             }
            '2022' { 
                if($VSProduct -eq "Professional"){                    
                    $MPC = "09662"
                }
                else {                    
                    $MPC = "09660"
                }
             }
            default { throw "Unsupported VisualStudioYear: $VSYear"}
        }
        Write-Verbose "Set Visual Studio Key $storePID"
        $storePID = Join-Path -Path $enterprice.InstallationPath -ChildPath "Common7\IDE\StorePID.exe"
        & $storePID $VSKey $MPC
    }
    else {
        Write-Verbose "Visual Studio Already Installed at $($visualstudio.InstallationPath)"
    }
    
    if(-not $SkipRemoveOlderVersion.IsPresent)
    {
        $pattern = "VisualStudio\.(\d+)\."
        $visualstudio = Get-VisualStudioInstance -Verbose:$isVerbose | Where-Object { $_.ProductId -like "*$VSProduct"-and $_.ChannelId -like '*Release' -and $_.ChannelId -notlike $ChannelId }
        $visualstudio | ForEach-Object {
            if ($_.ChannelId -match $pattern) {
                $version = $matches[1]
                $y = $null
                switch ($version)
                {
                '16' { $y = "2019" }
                '17' { $y = "2022" }
                }
                if($y){
                    Write-Warning "Remove Visual Studio $VSProduct $y"
                    Remove-VisualStudioProduct -Verbose:$isVerbose `
                        -PackageName $VSPackage `
                        -Product $VSProduct `
                        -VisualStudioYear $y `
                        -Preview $false                
                }
            }
        }
    }

    Set-SDK -Verbose:$isVerbose

    if(-not $VsixUrl){
        $VsixUrl = Get-VsixUrl -PackageId "SharpPS.VisualStudio.Sitecore.Package.6fcc4f27-b50e-40fa-ab1b-5e588ac40eef"
    }

    if(-not ($VsixUrl -eq "skip")){
        Write-Verbose "Install SharpPS Tools via $VsixUrl"
        $env:ChocolateyIgnoreChecksums='true'
        Install-VisualStudioVsixExtension -Verbose:$isVerbose -PackageName SharpPS.VisualStudio.Sitecore.Package.6fcc4f27-b50e-40fa-ab1b-5e588ac40eef -VsixUrl $VsixUrl
    }
    else{
         Write-Verbose "Skip Install SharpPS Tools"
    }
    return $visualstudio
}