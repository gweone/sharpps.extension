Function Invoke-SharpPSSitecoreHeadless
{
    Param(
	    [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
	    [string]$PublishPath,
        [Parameter(Mandatory = $True)]
	    [string]$Url,
        [Parameter(Mandatory = $True)]
	    [string]$Version,
	    [string]$Username,
	    [string]$Password
    )

    $scriptArgs = @{ "PublishPath" = $PublishPath
               "Version" = $Version 
             }
    $scriptBlock = {
        $headlessUrl = "https://scdp.blob.core.windows.net/downloads/Sitecore%20Headless%20Rendering/22x/Sitecore%20Headless%20Rendering%202200/Secure/Sitecore%20Headless%20Services%20Server%20XP%2022.0.11.zip"
        $headlessZip = Join-Path -Path $params.PublishPath -ChildPath "App_Data\packages\Sitecore Headless Services Server.zip"
        if($params.Version.StartsWith("10.0"))
        {
            $headlessUrl = "https://scdp.blob.core.windows.net/downloads/Sitecore%20JavaScript%20Services/150/Sitecore%20JavaScript%20Services%201501/Secure/ZIP/Sitecore%20JavaScript%20Services%20Server%20for%20Sitecore%2010.0.0%20XP%2015.0.1%20rev.%20201112.zip"
        }
        elseif($params.Version.StartsWith("10.1"))
        {
            $headlessUrl = "https://scdp.blob.core.windows.net/downloads/Sitecore%20Headless%20Rendering/18x/Sitecore%20Headless%20Rendering%201800/Secure/Sitecore%20Headless%20Services%20Server%20XP%2018.0.0%20rev.%2000473.zip"
        }
        elseif($params.Version.StartsWith("10.2"))
        {
            $headlessUrl = "https://scdp.blob.core.windows.net/downloads/Sitecore%20Headless%20Rendering/20x/Sitecore%20Headless%20Rendering%202002/Secure/Sitecore%20Headless%20Services%20Server%20XP%2020.0.2%20rev.%2000545.zip"
        }
        elseif($params.Version.StartsWith("10.3"))
        {
            $headlessUrl = "https://scdp.blob.core.windows.net/downloads/Sitecore%20Headless%20Rendering/21x/Sitecore%20Headless%20Rendering%202101/Secure/Sitecore%20Headless%20Services%20Server%20XP%2021.0.587.zip"
        }
        elseif($params.Version.StartsWith("9.3"))
        {
            $headlessUrl = "https://scdp.blob.core.windows.net/downloads/Sitecore%20JavaScript%20Services/130/Sitecore%20JavaScript%20Services%201300/Secure/ZIP/Sitecore%20JavaScript%20Services%20Server%20for%20Sitecore%209.3%20XP%2013.0.0%20rev.%20190924.zip"
        }

        if (-Not (Test-Path -Path $headlessZip))  {
            Write-Information "Download Sitecore Headless Service from $headlessUrl"
            Invoke-WebRequest -Uri $headlessUrl -OutFile $headlessZip
        }
        else
        {
            Write-Information "Headless Service Already Instaled"
            Return
        }
        Install-Package -Path $headlessZip -InstallMode Merge -MergeMode Merge -Verbose
    }
    $session = Invoke-SPESession -Url $Url -Username $Username -Password $Password
    Invoke-RemoteScript -Session $session -ScriptBlock $scriptBlock -ArgumentList $scriptArgs -Verbose -Raw
    Stop-ScriptSession -Session $session
}