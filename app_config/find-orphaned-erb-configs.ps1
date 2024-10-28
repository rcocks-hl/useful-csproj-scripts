# Get all app.config.erb files in the current directory and subdirectories
$erbFiles = Get-ChildItem -Recurse -Filter "app.config.erb"

foreach ($erbFile in $erbFiles) {
    $directory = $erbFile.DirectoryName
    $appConfigPath = Join-Path $directory "app.config"
    
    # Check if corresponding app.config exists
    if (!(Test-Path $appConfigPath -PathType Leaf)) {
        Write-Host "Found orphaned app.config.erb file: $($erbFile.FullName)"
    }
}

Write-Host "Finished searching for orphaned app.config.erb files"
