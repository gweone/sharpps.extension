Set-ExecutionPolicy Bypass -Scope Process -Force; 
$choco = Get-Command -Name "choco" -ErrorAction SilentlyContinue
if(-not $choco){
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

$sharpps = choco list sharpps.extension | Where-Object { $_ -like "sharpps.extension*" } | Select-Object -First 1
if(-not $sharpps){
    choco install chocolatey-visualstudio.extension -y
    choco install sharpps.extension -y --source https://www.myget.org/F/sharpps/api/v2
}

Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1 -Force
Import-Module $env:ChocolateyInstall\helpers\chocolateyInstaller.psm1 -Force

New-SharpPSSitecore -Verbose `
                    -SolutionName "Sitecore10" `
                    -TargetDirectory "C:\Projects" `
                    -Url https://sitecore.dev.wsc `
                    -SitecorePath C:\inetpub\wwwroot\sitecore.dev.wsc `
                    -Version 10.4.0 `
                    -IncludeRecommended