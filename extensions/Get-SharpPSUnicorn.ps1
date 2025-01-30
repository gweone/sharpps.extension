Function Get-SharpPSUnicorn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string]$Path,
        [string]$Destination = "items",
        [string[]]$Filters = @("*"),
        [switch]$Force
    )

    $verbose = ($VerbosePreference -eq "Continue")
    Set-SDK -Verbose:$verbose
    $files = Get-ChildItem -Path $Path -Recurse | Where-Object {
                $destFile = Join-Path -Path $Destination -ChildPath $_.FullName.Substring($Path.Length)
                if ($Force.IsPresent -or -not (Test-Path $destFile) -or ($_.LastWriteTime -gt (Get-Item $destFile).LastWriteTime)) {
                    return $true
                }
                return $false
             } | ForEach-Object {
                $itemType = if ($_.PSIsContainer) { "Directory" } else { "File" }
                [PSCustomObject]@{
                    FullName     = $_.FullName
                    ItemType = $itemType
                }
             }

    return $files | Where-Object ItemType -eq "File" | ForEach-Object {
                $file = $_
                $yaml = Get-SharpPSYaml -Verbose:$verbose -IncludeSystemField -Content (Get-Content -Path $file.FullName | Where-Object { $_.Trim() -ne "" } | Out-String)
                $yaml = $yaml | Where-Object { $_ -ne $null } | ForEach-Object {
                    [PSCustomObject]@{
                        Path = $_.Path
                        ID = $_.ID
                    }
                } | Select-Object -First 1

                if($yaml){
                    [PSCustomObject]@{
                        Path = $yaml.Path
                        ID = $yaml.ID
                        FullName     = $_.FullName
                        ItemType = $_.ItemType
                    }
                }
                else {
                    $null
                }

            } | Where-Object {
                $y = $_
                $null -ne $y -and ($Filters | Where-Object { $y.Path -like $_ -or $y.ID -like $_ })
            }
}