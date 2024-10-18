# Function to remove binding redirects for a specific package
function Remove-BindingRedirects {
    param (
        [xml]$ConfigXml
    )

    $runtime = $ConfigXml.configuration.runtime;

    if($runtime -eq $null){
        return $false;
    }

    $ConfigXml.configuration.RemoveChild($ConfigXml.configuration.runtime) | Out-Null
    
    return $true;
}

# Get all app.config files in the current directory and subdirectories
$configFiles = Get-ChildItem -Recurse -Filter app.config

foreach ($file in $configFiles) {
    $content = Get-Content $file.FullName -Raw
    $xml = [xml]$content

    $modified = Remove-BindingRedirects -ConfigXml $xml

    if ($modified) {
        $xml.Save($file.FullName)
        Write-Host "Removed binding redirects from $($file.FullName)"
    } else {
        Write-Host "No binding redirects found in $($file.FullName)"
    }
}

Write-Host "Finished processing all app.config files"
