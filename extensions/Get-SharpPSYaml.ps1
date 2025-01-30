Function Get-SharpPSYaml {
    [CmdletBinding()]
    Param(
        [string]$Content,
        [switch]$IncludeSystemField
    )

    if(-not $Content) {
        return $null
    }

    $Content = $Content -Replace '@', ""
    $y = ConvertFrom-Yaml -Yaml $Content -ErrorAction SilentlyContinue

    if(-not $y){
        return $null
    }

    if($y.ContainsKey("SharedFields"))
    {
        $y.SharedFields | Where-Object {
            $IncludeSystemField.IsPresent -or $_.Hint -NotLike "__*" -or ($_.ContainsKey("Type") -and $_.Type -eq "layout")
        } | ForEach-Object {
            [PSCustomObject]@{
                ID = $y.ID
                Path = $y.Path
                Language = "shared"
                Version = 0
                FieldName = $_.Hint
                FieldValue = $_.Value
            }
        }
    }
    if($y.ContainsKey("Languages")){
        $y.Languages | ForEach-Object {
            $lang = $_.Language
            $_.Versions | ForEach-Object {
                $v = $_.Version
                if($_.ContainsKey("Fields")){
                    $_.Fields | Where-Object {
                        $IncludeSystemField.IsPresent -or $_.Hint -NotLike "__*"
                    } | ForEach-Object {
                        [PSCustomObject] @{
                            ID = $y.ID
                            Path = $y.Path
                            Language = $lang
                            Version = $v
                            FieldName = $_.Hint
                            FieldValue = $_.Value
                        }
                    }
                }
            } 
        }
    }
}