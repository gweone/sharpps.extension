Function Get-VsixUrl {

    Param(
        [Parameter(Mandatory = $true)][string]$PackageId,
        [string]$FeedUrl = "https://www.myget.org/F/sharpps/vsix"
    )

    # Fetch the XML content from the URL
    $response = Invoke-WebRequest -Uri $FeedUrl
    [xml]$xml = $response.Content
    
    # Find entries with the specified ID
    $entries = $xml.feed.entry | Where-Object { $_.id -eq $PackageId }

    # If there are no entries, output an error message
    if (-not $entries) {
        Throw "No entries found for the specified ID."
    }

    # Determine the latest version
    $latestEntry = $entries | Sort-Object { [version]$_.Vsix.Version } -Descending | Select-Object -First 1
    
    return $latestEntry.content.src
}