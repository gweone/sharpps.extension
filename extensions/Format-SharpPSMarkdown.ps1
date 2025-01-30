Function Format-SharpPSMarkdown {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [object]$InputObject,
        [Parameter()]
        [string[]]
        $Property = @()
    )

    Begin {
        $NeedToReturn = $false
        if ($null -ne $InputObject -and $InputObject.GetType().BaseType -eq [System.Array]) {
            Write-Error "InputObject must not be System.Array. Don't use InputObject, but use the pipeline to pass the array object."
            $NeedToReturn = $true
            return
        }

        $Result = @()
    }

    Process {
        if ($NeedToReturn) { return }
        if (($Property.Length -eq 0) -or ($Property.Length -eq 1 -and $Property[0] -eq "")) {
            $Property = @("*")
        }

        $CurrentObject = $null
        if ($_ -eq $null) {
            $CurrentObject = $InputObject
        }
        else {
            $CurrentObject = $_
        }

        $Props = $CurrentObject | Get-Member -Name $Property -MemberType Property, NoteProperty | Select-Object -ExpandProperty Name 
        if ($CurrentObject -is [hashtable]){
            $Props = $Property
            if($Property[0] -eq "*"){
                 $Props = $CurrentObject.Keys
            }
        }

        if($Result.Count -eq 0){
           $Result += '|' + (($Props | ForEach-Object{ EscapeMarkdown($_) }) -join '|') + '|'
           $Result += '|' + (($Props | ForEach-Object{ "------" }) -join '|') + '|' 
        }

        $Row = $Props | ForEach-Object {  EscapeMarkdown($CurrentObject.($_))  }
        $Result += '|' + ($Row -join '|') + '|'
    }
    End {
        if ($NeedToReturn) { return }
        $Result | Out-String
    }
    
}

Function EscapeMarkdown([object]$InputObject) {
    $Temp = ""

    if ($null -eq $InputObject) {
        return ""
    }
    elseif ($InputObject.GetType().BaseType -eq [System.Array]) {
        $Temp = "{" + [System.String]::Join(", ", $InputObject) + "}"
    }
    elseif ($InputObject.GetType() -eq [System.Collections.ArrayList] -or $InputObject.GetType().ToString().StartsWith("System.Collections.Generic.List")) {
        $Temp = "{" + [System.String]::Join(", ", $InputObject.ToArray()) + "}"
    }
    elseif (Get-Member -InputObject $InputObject -Name ToString -MemberType Method) {
        $Temp = $InputObject.ToString()
    }
    else {
        $Temp = ""
    }

    return $Temp.Replace("\", "\\").Replace("*", "\*").Replace("_", "\_").Replace("``", "\``").Replace("$", "\$").Replace("|", "\|").Replace("<", "\<").Replace(">", "\>").Replace("`r`n", "<br />").Replace("`n", "<br />")
}