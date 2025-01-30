Function Invoke-SharpPSChanges {
    [CmdletBinding()]
    param(
        [string]$FirstCommitHash,
        [string]$LastCommitHash = "HEAD",  
        [string]$PublishedPath = "published",
        [string]$ArtifactPath,
        [string]$Version = "1.0",
        [string]$RootPath= ".",
        [hashtable]$Configuration= @{},
        [switch]$SkipPackage
    )
    
    Set-SharpPSPolicy
    $verbose = ($VerbosePreference -eq "Continue")
    Set-SDK -Verbose:$verbose
    if (-Not (Test-Path -Path $PublishedPath)) {
        New-Item -Path $PublishedPath -ItemType Directory | Out-Null
    }

    if(-not $ArtifactPath){
        $ArtifactPath = $PublishedPath
    }

    if(-not (Test-Path $ArtifactPath))
    {
        New-Item -Path $ArtifactPath -ItemType Directory | Out-Null
    }
	
    if([string]::IsNullOrEmpty($FirstCommitHash))
    {
        $FirstCommitHash=$(git rev-list --max-parents=0 HEAD)
    }

    if([string]::IsNullOrEmpty($PublishedPath))
    {
        $PublishedPath = Get-Location | Select-Object -ExpandProperty Path | Join-Path -Path {$_} -ChildPath "published"
    }

    Function Get-CmsChanges
    {
        $extension = "*.yml"
        $manualFilters = @()
        $paths = @("items/")
        $scopes = @()
        $excludes = @()
        if ($null -ne $Configuration -and $Configuration.ContainsKey("Cms")) {
            if ($Configuration.Cms.ContainsKey("Extension")) {
                $extension = $Configuration.Cms.Extension
            }
            if ($Configuration.Cms.ContainsKey("Filters")) {
                $manualFilters = $Configuration.Cms.Filters
            }
            if ($Configuration.Cms.ContainsKey("Paths")) {
                $paths = $Configuration.Cms.Paths
            }
            if ($Configuration.Cms.ContainsKey("Scopes")) {
                $scopes = $Configuration.Cms.Scopes
            }
            if ($Configuration.Cms.ContainsKey("Excludes")) {
                $scopes = $Configuration.Cms.Excludes
            }
        }
        else {
            Write-Verbose "For override set configuration with Cms = @{Filters, Paths}"
        }
        
        Write-Verbose "Get Cms Changes in $paths"
        $cmsChanges = Invoke-SharpPSGit $FirstCommitHash $LastCommitHash $paths | Where-Object FileName -like $extension 
        Write-Verbose "Filter Manual Changes with $manualFilters"
        return $cmsChanges | ForEach-Object {
            # Custom logic to create a new PowerShell object
            $item = $_
            $c = Get-Content -Path $item.Filename -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -ne "" } | Out-String
            if($c)
            {
                $c = $c -Replace '@', ""
            }

            if ($cmsChanges -is [array]) {
                $i = [array]::IndexOf($cmsChanges, $item) + 1
                Write-Progress "Process yaml of $($item.Filename)" -PercentComplete (($i/$cmsChanges.Length) * 100 )
            }

            $y = ConvertFrom-Yaml -Yaml $c -ErrorAction SilentlyContinue
            if(-not $y)
            {
               return [PSCustomObject]@{
                        Action = ""
                        Status = $item.Status
                        Scope = ""
                        ID = ""
                        Path = $c
                        FileName = $item.FileName
                    }
            }
            else
            {
                $action = $null
                if($manualFilters | Where-Object { $y.Path -like $_ -or $y.ID -like $_ })
                {
                    $action = "Manual"
                }

                $scope = "content"
                if($y.Path.StartsWith("/sitecore/templates"))
                {
                    $scope = "templates"
                }
                elseif($y.Path.StartsWith("/sitecore/layout"))
                {
                    $scope = "layout"
                }
                elseif($y.Path.StartsWith("/sitecore/system"))
                {
                    $scope = "system"
                }
                elseif($y.Path.StartsWith("/sitecore/media library"))
                {
                    $scope = "media"
                }
                elseif($y.Path.StartsWith("/sitecore/Forms"))
                {
                    $scope = "forms"
                }
                
                $selected = $null
                $scopes | ForEach-Object {
                    if($y.Path -like "*$_*")
                    {
                        $selected = "$_.$scope"
                    }
                }
                if($selected){
                    $scope = $selected
                }
            
                return [PSCustomObject]@{
                        Action = $action
                        Status = $item.Status
                        Scope = $scope
                        ID = $y.ID
                        Path = $y.Path
                        FileName = $item.FileName
                    }
            }
        
        } | Where-Object {
            $include = $true
            foreach ($pattern in $excludes) {
                if ($_.ID -like $pattern -or $_.Path -like $pattern) {
                    $include = $false
                    break
                }
            }
            return $include            
        } | Sort-Object Scope, Path  

    }

    Function Get-ContentChanges
    {
        $manualFilters = @()
        $paths = @()
        $paths += Get-ChildItem -Filter "*.Database" -Directory -Recurse | ForEach-Object { Resolve-Path -Relative $_.FullName }
        $paths += @("src/foundation", "src/feature", "src/project") | Where-Object { Test-Path $_ }
        $includeFilter = @("App_Config", "App_Data", "Areas", "Views", "css", "fonts", "images", "js", "json")
        $externalLibs = @()
        $excludes = @()

        if($Configuration -and $Configuration.ContainsKey("Content")){
            if($Configuration.Content.ContainsKey("Filters")){
                $manualFilters = $Configuration.Content.Filters
            }
            if($Configuration.Content.ContainsKey("Paths")){
                $paths = $Configuration.Content.Paths
            }
            if($Configuration.Content.ContainsKey("Includes")){
                $includeFilter = $Configuration.Content.Includes
            }
            if($Configuration.Content.ContainsKey("Excludes")){
                $excludes = $Configuration.Content.Excludes
            }
            if($Configuration.Content.ContainsKey("ExternalLibs")){
                $externalLibs = $Configuration.Content.ExternalLibs
            }
        }
        else {
            Write-Verbose "For override set configuration with Content = @{Filters, Paths, Includes}"
        }

        Write-Verbose "Get Content Changes in $paths"
        $codeChanges = Invoke-SharpPSGit $FirstCommitHash $LastCommitHash $paths | Where-Object {
            $include = $true
            foreach ($pattern in $excludes) {
                if ($_.FileName -like $pattern) {
                    $include = $false
                    break
                }
            }
            return $include
        }
        Write-Verbose "Filter Manual Changes with $manualFilters"
        $contentChanges = $codeChanges | Where-Object -Property Status -NE "Deleted" | ForEach-Object{

            $action = $null
            $item = $_
            if($manualFilters | Where-Object { $item.FileName -like $_ })
            {
                $action = "Manual"
            }
            $scope = $null
            foreach ($folder in $includeFilter) {
                if ($_.FileName -match "/$folder/") {
                    $scope = $folder
                    break
                }
            }
            $path = $_.FileName
            if($scope){
                $path = $path -split "/$scope/" | Select-Object -Last 1
                $path = "$scope/$path"
            }
            [PSCustomObject]@{
                Action = $action
                Scope = $scope
                Status = $_.Status
                FileName = $path
                SourceFileName = $_.FileName
            }

        } | Where-Object -Property Scope -ne $null

        $contentChanges += $codeChanges | Where-Object { $_.FileName -like "*.cs" -or $_.FileName -like ".csproj" } | ForEach-Object {
            $name = Get-Project -Path $_.FileName
            if(-not $name -or [string]::IsNullOrEmpty($name))
            {
                $null
            }
            else{
                $name = $name -replace " ", ""
            }
            [PSCustomObject]@{
                    Action = $null
                    Scope = "bin"
                    Status = "Modified"
                    FileName = "bin/$name.dll"
                    SourceFileName = ""
                }
        } | Select-Object * -Unique

        Write-Verbose "Filter External Libs with $externalLibs"
        $contentChanges += $externalLibs | ForEach-Object {
            Get-ChildItem -Path "$PublishedPath\bin" -Filter $_ -File | ForEach-Object {
                [PSCustomObject]@{
                    Action = $null
                    Scope = "bin"
                    Status = "Modified"
                    FileName = "bin/$($_.Name)"
                    SourceFileName = ""
                }
            }
        
        }
        
        return $contentChanges
    }

    Function Get-Project
    {
        Param(
            [string]$Path
        )
        
        $currentDir = Split-Path -Path $Path -Parent
        do {
            $csprojPath = Get-ChildItem -Path $currentDir -Filter "*.csproj" -File | Select-Object -ExpandProperty FullName -First 1
            if ($csprojPath) {
                $xml = [xml](Get-Content $csprojPath)
                if($xml.Project.PropertyGroup.GetType() -eq [System.Xml.XmlElement]){
                    return [System.IO.Path]::GetFileNameWithoutExtension($csprojPath)
                }
                if($xml.Project.PropertyGroup -is [array]) {

                    return $xml.Project.PropertyGroup | Where-Object { $null -ne $_.AssemblyName } | Select-Object -ExpandProperty AssemblyName -First 1
                }
                elseif($xml.Project.PropertyGroup -and $xml.Project.PropertyGroup.ContainsKey("AssemblyName"))
                {
                    if($xml.Project.PropertyGroup.AssemblyName -is [array])
                    {
                        return $xml.Project.PropertyGroup.AssemblyName | Select-Object -First 1
                    }
                    return $xml.Project.PropertyGroup.AssemblyName
                }
                return [System.IO.Path]::GetFileNameWithoutExtension($csprojPath)
            }
            $currentDir = Split-Path -Path $currentDir -Parent
        } while ($null -ne $currentDir)
        return $null
    }

    Function Get-DatabaseChanges
    {
        $paths = Get-ChildItem -Filter "App_Data" -Directory -Recurse | ForEach-Object { Resolve-Path -Relative $_.FullName }
        $scopes = @("Manual")
        $excludes = @()
        if($Configuration -and $Configuration.ContainsKey("Database")){
            if($Configuration.Database.ContainsKey("Paths")){
                $paths = $Configuration.Database.Paths
            }
            if($Configuration.Database.ContainsKey("Scopes")){
                $scopes = $Configuration.Database.Scopes
            }
            if($Configuration.Database.ContainsKey("Excludes")){
                $excludes = $Configuration.Database.Excludes
            }
        }
        else {
            Write-Verbose "For override set configuration with Database = @{Paths}"
        }
        
        Write-Verbose "Get Database Changes in $paths"
        $databaseChanges = Invoke-SharpPSGit $FirstCommitHash $LastCommitHash $paths | Where-Object {
            $include = $true
            foreach ($pattern in $excludes) {
                if ($_.FileName -like $pattern) {
                    $include = $false
                    break
                }
            }
            return $include
        }
        $databaseChanges = $databaseChanges | Where-Object { $_.FileName -like "*.sql" -and $_.Status -ne "Deleted" } 
        return $databaseChanges | ForEach-Object {
            $scope = "Global"
            $item = $_

            $scopes | ForEach-Object {
                if( $item.FileName -like "*$_*")
                {
                    $scope = $_
                }
            }
            $path = Split-Path $_.FileName -Leaf
            [PSCustomObject]@{
                Scope = $scope
                Status = $_.Status
                FileName = "$scope/$path"
                SourceFileName = $_.FileName
            }

        } | Sort-Object -Property Scope, FileName
    }

    $documentationPath = Join-Path $ArtifactPath -ChildPath "documentation"
    if(Test-Path $documentationPath)
    {
        Remove-Item -Path $documentationPath -Recurse -Force
    }
    New-Item -Path $documentationPath -ItemType Directory | Out-Null

    $cmsChanges = Get-CmsChanges
    if($cmsChanges)
    {
        $cmsChanges | Export-Csv -Path "$documentationPath\cms-changes.csv" -NoTypeInformation -Verbose:$verbose
        $cmsChanges | Where-Object { $_.Action -eq "Manual" }  | ForEach-Object {
            $state = $_
            $current = Get-SharpPSYaml -Content (Get-Content -Path $state.FileName | Where-Object { $_.Trim() -ne "" } | Out-String)
            $older = Get-SharpPSYaml -Content (Get-GitContent -Path $state.FileName -CommitHash $FirstCommitHash | Where-Object { $_.Trim() -ne "" } | Out-String)
            $current | ForEach-Object {
                $field = $_
                $filter = {
                    $_.ID -eq $field.ID -and $_.Language -eq $field.Language -and $_.Version -eq $field.Version -and $_.FieldName -eq $field.FieldName
                }

                $olderValue = $null
                if($older){
                    $olderValue = $older | Where-Object $filter | Select-Object -ExpandProperty FieldValue -First 1
                }

                [PSCustomObject]@{
                    Status = $state.Status
                    FileName = $state.FileName
                    ID = $field.ID
                    Path = $field.Path
                    Language = $field.Language
                    Version = $field.Version
                    FieldName = $field.FieldName
                    CurrentValue = $field.FieldValue
                    OlderValue = $olderValue
                    FieldStatus = ($field.FieldValue -eq $olderValue)
                }
            }
        } | Where-Object FieldStatus -eq $false | Export-Csv -Path "$documentationPath\cms-changes.manual.csv" -NoTypeInformation -Verbose:$verbose
    }
    else {
        Write-Warning "No Changes in Cms"
    }
    
    $contentChanges = Get-ContentChanges
    if($contentChanges) {
        $contentChanges | Sort-Object -Property Scope | Export-Csv -Path "$documentationPath\content-changes.csv" -NoTypeInformation -Verbose:$verbose
        $contentChanges | Where-Object { $_.Action -eq "Manual" } | ForEach-Object {
            Get-SharpPSGitCompare -Path $_.SourceFileName -CommitHash $FirstCommitHash
        } | Export-Csv -Path "$documentationPath\content-changes.manual.csv" -NoTypeInformation -Verbose:$verbose    
    }
    else{
        Write-Warning "No Changes in Content"
    }

    $databaseChanges = Get-DatabaseChanges
    if($databaseChanges){
        $databaseChanges | Export-Csv -Path "$documentationPath\database-changes.csv" -NoTypeInformation -Verbose:$verbose
    }
    else{
        Write-Warning "No Changes in Database"
    }

    #COPY FILES .........
    #=========================================================

    #Copy cms packages
    $targetPath = Join-Path $ArtifactPath -ChildPath "packages"
    if(Test-Path $targetPath)
    {
        Remove-Item -Path $targetPath -Recurse -Force
    }
    New-Item -Path $targetPath -ItemType Directory | Out-Null

    if(-not $SkipPackage.IsPresent -and $null -ne $cmsChanges)
    {
        $package = @{
            Name = "SharpPS"
            Url = "https://sitecore.dev.wsc"
            Username = "admin"
            Password = "P@ssw0rd"
        }
        if($Configuration -and $Configuration.ContainsKey("Package")){
            $package = $Configuration.Package
        }
        else {
            Write-Verbose "For override set configuration with Package = @{Name, Url, Username, Password}"
        }

        $cmsChanges | Where-Object { $_.Action -ne "Manual" -and $_.Status -NE "Deleted" } | Group-Object -Property Scope | ForEach-Object {
            $group = $_
            $paths = $group.Group | Select-Object -ExpandProperty Path
            Write-Verbose "Create-Package for $($package.Name).$($_.Name)"
            Invoke-SharpPSSitecorePackage -Url $package.Url -DestinationPath $targetPath -Name "$($package.Name).$($group.Name)" -Version $Version -Paths $paths -Username $package.Username -Password $package.Password
        }
    }

    #Copy content file
    if($contentChanges){
        $contentPath = Join-Path $ArtifactPath -ChildPath "inetpub"
        $contentChanges | ForEach-Object { 
            if($_.Action -eq "Manual")
            {
                $targetPath = Join-Path $contentPath -ChildPath "manual"
            }
            else
            {
                $targetPath = Join-Path $contentPath -ChildPath "www"
            }

            $filePath = $_.FileName
            $dir = Split-Path $filePath

            $targetPath = Join-Path $targetPath -ChildPath $dir
            if (-Not (Test-Path -Path $targetPath)) {
                New-Item -Path $targetPath -ItemType Directory | Out-Null
            }
            $sourcePath = Join-Path $PublishedPath -ChildPath $filePath
            if (Test-Path -Path $sourcePath) {
                Copy-Item $sourcePath -Destination $targetPath -Force
            }    
        }
    }

    #Copy database file
    if($databaseChanges){
        $databasePath = Join-Path $ArtifactPath -ChildPath "database"
        $databaseChanges | ForEach-Object { 
            if (-Not (Test-Path -Path $databasePath)) {
                New-Item -Path $databasePath -ItemType Directory | Out-Null
            }

            $targetPath = Join-Path $databasePath -ChildPath $_.Scope
            if (-Not (Test-Path -Path $targetPath)) {
                New-Item -Path $targetPath -ItemType Directory | Out-Null
            }
            Copy-Item $_.SourceFileName -Destination $targetPath -Force
        }
    }

    return @{
        Cms = $cmsChanges
        Content = $contentChanges
        Database = $databaseChanges
    }
}
