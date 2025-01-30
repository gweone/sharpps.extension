Function Invoke-SPESession
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string]$Url,
	    [string]$Username,
	    [string]$Password
    )

    if([string]::IsNullOrEmpty($Username))
    {
        $Username = "sitecore\admin"
    }

    if([string]::IsNullOrEmpty($Password))
    {
        $Password = "b"
    }
    Import-Module -Name SPE -Force
    New-ScriptSession -Username $Username -Password $Password -ConnectionUri $Url -Timeout 10
}