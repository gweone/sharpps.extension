Function Invoke-SharpPSSitecoreSPE
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)][string]$SitecorePath
    )

    $filesDirectory = Join-Path -Path $PSScriptRoot -ChildPath "files"
    if(-not (Test-Path $filesDirectory))
    {
        Write-Verbose "Create directory for downloaded files at $filesDirectory"
        New-Item $filesDirectory -ItemType Directory | Out-Null
    }

    $modulePath = $env:PSModulePath -split ";" | Where-Object {$_ -like "*Program Files*"} | Select-Object -First 1

    $speMinimalZip = Join-Path -Path $filesDirectory -ChildPath "SPE.Minimal.zip"
    $speRemotingZip = Join-Path -Path $filesDirectory -ChildPath "SPE.Remoting.zip"
    if (-Not (Test-Path -Path $speMinimalZip) -or -Not (Test-Path -Path $speRemotingZip)) {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/SitecorePowerShell/Console/releases/latest" -Headers @{ "User-Agent" = "PowerShell" }
        $speUrl = $response.assets | Where-Object { $_.name -like "SPE.Minimal-*.zip" } | Select-Object -ExpandProperty browser_download_url -First 1
        $speRemoteUrl = $response.assets | Where-Object { $_.name -like "SPE.Remoting-*.zip" } | Select-Object -ExpandProperty browser_download_url -First 1
    }

    if (-Not (Test-Path -Path $speMinimalZip)) {
        Write-Verbose "Download SPE Minimal $speUrl"
        Invoke-WebRequest -Uri $speUrl -OutFile $speMinimalZip
    }

    if (-Not (Test-Path -Path $speRemotingZip) -and -not (Test-Path -Path "$modulePath\SPE")) {
        Write-Verbose "Download SPE Remoting from $speRemoteUrl"
        Invoke-WebRequest -Uri $speRemoteUrl -OutFile $speRemotingZip
    }

    try{
        # Extract the ZIP file
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        if (-Not (Test-Path -Path "$modulePath\SPE"))
        {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($speRemotingZip, $modulePath)
        }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($speMinimalZip, $SitecorePath)
    }
    catch
    {
        Write-Host "SPE already Installed" -ForegroundColor Green
        Write-Verbose $_
        Import-Module -Name SPE -Force
    }

    $xmlFilePath = "$SitecorePath\App_Config\Include\Spe\spe.config"
    [xml]$xml = Get-Content -Path $xmlFilePath
    $remotingElement = $xml.SelectSingleNode("configuration/sitecore/powershell/services/remoting")
    if ($null -ne $remotingElement) {
        if($remotingElement.enabled -eq "false")
        {
            $remotingElement.enabled = "true";
            $xml.Save($xmlFilePath)
        }
      Write-Host "Remote service is enabled"
    } else {
        Write-Host "The <remoting> element was not found in the XML file."
    }

    $fileDownloadElement = $xml.SelectSingleNode("configuration/sitecore/powershell/services/fileDownload")
    if ($null -ne $fileDownloadElement) {
        if($fileDownloadElement.enabled -eq "false")
        {
            $fileDownloadElement.enabled = "true";
            $xml.Save($xmlFilePath)
        }
      Write-Host "File download is enabled"
    } else {
        Write-Host "The <fileDownload> element was not found in the XML file."
    }

    Import-Module -Name SPE -Force
}