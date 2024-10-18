param(
    [Parameter(Mandatory=$true)]
    [string]$PackageName
)

# Function to remove binding redirects for a specific package
function Remove-BindingRedirect {
    param (
        [xml]$ConfigXml,
        [string]$PackageName
    )

    $assemblyBinding = $ConfigXml.configuration.runtime.assemblyBinding
    if ($assemblyBinding -eq $null) {
        return $false
    }

    $modified = $false
    $nodesToRemove = @()

    foreach ($dependentAssembly in $assemblyBinding.dependentAssembly) {
        if ($dependentAssembly.assemblyIdentity.name -eq $PackageName) {
            $nodesToRemove += $dependentAssembly
            $modified = $true
        }
    }

    foreach ($node in $nodesToRemove) {
        $assemblyBinding.RemoveChild($node) | Out-Null
    }

    # Remove assemblyBinding if it's empty
    if ($assemblyBinding.dependentAssembly.Count -eq 0) {
        $ConfigXml.configuration.runtime.RemoveChild($assemblyBinding) | Out-Null
    }

    # Remove runtime if it's empty
    if ($ConfigXml.configuration.runtime.ChildNodes.Count -eq 0) {
        $ConfigXml.configuration.RemoveChild($ConfigXml.configuration.runtime) | Out-Null
    }

    return $modified
}

# Get all app.config files in the current directory and subdirectories
$configFiles = Get-ChildItem -Recurse -Filter app.config

foreach ($file in $configFiles) {
    $content = Get-Content $file.FullName -Raw
    $xml = [xml]$content

    $modified = Remove-BindingRedirect -ConfigXml $xml -PackageName $PackageName

    if ($modified) {
        $xml.Save($file.FullName)
        Write-Host "Removed binding redirect for $PackageName from $($file.FullName)"
    } else {
        Write-Host "No binding redirect found for $PackageName in $($file.FullName)"
    }
}

Write-Host "Finished processing all app.config files"
