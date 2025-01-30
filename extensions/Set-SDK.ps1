Function Set-SDK {

    try {
        $dotnetSdks = & dotnet --list-sdks 2>&1
        if ($dotnetSdks -match "^\d+\.\d+\.\d+") {
            Write-Verbose "The .NET SDK is installed"
        } else {
            choco install dotnet-sdk -y
        }
    } catch {
        choco install dotnet-sdk -y
    }

    $git = Get-Command -Name "git" -ErrorAction SilentlyContinue
    if(-not $git){
        Write-Verbose "Git command not exists. it will be install"
        choco install git -y
    }
    $isVerbose = $VerbosePreference -eq "Continue"    
    $c = Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue
    if(-not $c){
        Install-Module -Name powershell-yaml -Verbose:$isVerbose -Force -Confirm:$false
    }
}