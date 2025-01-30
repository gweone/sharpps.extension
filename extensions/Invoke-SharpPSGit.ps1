FUNCTION Invoke-SharpPSGit
{
    Param(
        [string]$FirstCommitHash,
        [string]$LastCommitHash,
        [string[]]$folders = @(".")
    )

    $isVerbose = $VerbosePreference -eq "Continue"
    Set-SDK -Verbose:$isVerbose

    Write-Verbose "Executing... `ngit diff --name-status $FirstCommitHash $LastCommitHash $folders"
    # Run 'git diff --name-status' and capture the output
    $gitDiffOutput = git diff --name-status $FirstCommitHash $LastCommitHash $folders

    # Parse the output into a structured format
    Return $gitDiffOutput | ForEach-Object {
        # Split the line on tabs
        $columns = $_ -split "`t"
        $status = switch ($columns[0]) {
                        "D" { "Deleted"; break }
                        "A" { "New"; break }
                        default { "Modified"; break }
                    }

        if ($columns.Count -eq 3) {
            [PSCustomObject]@{
                Status = $status
                FileName = $columns[2]
                OldFileName = $columns[1]
            }
        } elseif ($columns.Count -eq 2) {
            [PSCustomObject]@{
                Status = $status
                FileName = $columns[1]
                OldFileName = ""
            }
        } else {
            Write-Warning "Unexpected format: $_"
            continue
        }
    } | Sort-Object -Property FileName
}