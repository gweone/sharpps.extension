Function Invoke-SharpPSSitecorePackage
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
	    [string]$Url,
        [Parameter(Mandatory = $True)]
		[string]$DestinationPath,
        [Parameter(Mandatory = $True)]
        [string]$Name,
        [Parameter(Mandatory = $True)]
        [string]$Version,
        [string[]]$Paths,
        [string]$Query,
	    [string]$Username,
	    [string]$Password
    )

    $scriptArgs = @{ "Name" = $Name
               "Version" = $Version
               "Paths" = $Paths
               "Query" = $Query
             }
    $scriptBlock = {
        $package = New-Package $params.Name;

        # Set package metadata
        $package.Sources.Clear();

        $package.Metadata.Author = $params.Name -split "." | Select-Object -First 1;
        $package.Metadata.Publisher = $package.Metadata.Author;
        $package.Metadata.Version = $params.Version;
        $package.Metadata.Readme = "$($params.Name) Package"

        # Add content/home and all of its children to the package
        $source = Get-Item '/sitecore/content/*' | New-ExplicitItemSource -Name $params.Name
        if(-not [string]::IsNullOrEmpty($params.Query))
        {
            $items = Get-Item -Path "master:" -Query $params.Query -ErrorAction SilentlyContinue
        }
        else
        {
            $items = $params.Paths | ForEach-Object { Get-Item -Path "master:" -Query $_ -ErrorAction SilentlyContinue }
        }

        $items | ForEach-Object {
            $ref = [Sitecore.Install.Items.ItemReference]::new($_)
            $source.Entries.Add($ref.ToString())
        }
        $package.Sources.Add($source);
        # Save package
        Export-Package -Project $package -Path "$($package.Name)-$($package.Metadata.Version).zip" -Zip -Verbose

    }
    $session = Invoke-SPESession -Url $Url -Username $Username -Password $Password
    Invoke-RemoteScript -Session $session -ScriptBlock $scriptBlock -ArgumentList $scriptArgs -Verbose -Raw
    Receive-RemoteItem -Session $session -Path "App_Data\packages\$Name-$Version.zip" -RootPath App -Destination $DestinationPath -Verbose
    Stop-ScriptSession -Session $session
}