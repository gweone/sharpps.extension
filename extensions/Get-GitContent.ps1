Function Get-GitContent {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$CommitHash
    )

    try {
        $fileContent = git show "$($CommitHash):$Path" 2>&1
        return $fileContent | Where-Object { $_ -is [string]}
    } catch {
        return @()
    }
}
