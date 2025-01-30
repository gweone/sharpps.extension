Function Invoke-SharpPSSitecoreUnicorn
{
    Param(
        [Parameter(Mandatory = $True)]
	    [string]$Url,
	    [string[]]$Configurations,
	    [string]$Secret="749CABBC85EAD20CE55E2C6066F1BE375D2115696C8A8B24DB6ED1FD60613086",
        [switch]$DebugSecurity
    )
    $filesDirectory = Join-Path -Path $PSScriptRoot -ChildPath "files"
    if(-not (Test-Path $filesDirectory))
    {
        Write-Verbose "Create directory for downloaded files at $filesDirectory"
        New-Item $filesDirectory -ItemType Directory | Out-Null
    }

    $unicorn = Join-Path -Path $PSScriptRoot -ChildPath "MicroCHAP.dll"
    if(-not (Test-Path $unicorn))
    {
        $rawFileUrl = "https://raw.githubusercontent.com/SitecoreUnicorn/Unicorn/master/doc/PowerShell%20Remote%20Scripting/MicroCHAP.dll"
        Invoke-WebRequest -Uri $rawFileUrl -OutFile $unicorn

        $unicorn = Join-Path -Path $PSScriptRoot -ChildPath "Unicorn.psm1"
        $rawFileUrl = "https://raw.githubusercontent.com/SitecoreUnicorn/Unicorn/master/doc/PowerShell%20Remote%20Scripting/Unicorn.psm1"
        Invoke-WebRequest -Uri $rawFileUrl -OutFile $unicorn
    }

    Import-Module $unicorn -Force
    Sync-Unicorn -ControlPanelUrl "$Url/unicorn.aspx" -SharedSecret $Secret -Configurations $Configurations -StreamLogs -DebugSecurity:$DebugSecurity.IsPresent
}
