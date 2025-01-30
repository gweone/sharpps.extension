Function Start-SharpPSUp
{
    [CmdletBinding()]
    Param(
		[Parameter(Mandatory = $True)][string]$Url
    )
    Set-SharpPSPolicy
    try{
	    Write-Host "`nwarming up $Url ...."  -ForegroundColor Magenta
	    # Hit Url
	    Invoke-WebRequest -Uri $Url
    }
    catch {
	    Write-Host "`nWarming up failed" -ForegroundColor Red
	    Write-Host $_ -ForegroundColor Red
    }
}