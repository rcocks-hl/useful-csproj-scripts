# Function to check if a project is a library (not an executable or test project)
function Is-LibraryProject {
    param (
        [xml]$ProjectXml,
        [string]$ProjectPath
    )

    # Skip if project name contains .Test, .Tests, or TestCommon
    if ($ProjectPath -match "\.Tests?|TestCommon") {
        return $false
    }

    $propertyGroups = $ProjectXml.Project.PropertyGroup
    foreach ($propertyGroup in $propertyGroups) {
        # Check if it's an executable
        if ($propertyGroup.OutputType -eq "Exe" -or $propertyGroup.OutputType -eq "WinExe") {
            return $false
        }
    }

    # Check project references for test frameworks
    $packageReferences = $ProjectXml.SelectNodes("//PackageReference")
    foreach ($reference in $packageReferences) {
        $packageId = $reference.GetAttribute("Include")
        if ($packageId -match "NUnit3TestAdapter|xUnit|MSTest|TestSDK|FluentAssertions|Moq|NSubstitute") {
            return $false
        }
    }

    return $true
}

# Get all project files in the current directory and subdirectories
$projectFiles = Get-ChildItem -Recurse -Include *.csproj,*.vbproj

foreach ($projectFile in $projectFiles) {
    $projectDir = $projectFile.DirectoryName
    $appConfigPath = Join-Path $projectDir "app.config"
    
    # Only proceed if app.config exists
    if (Test-Path $appConfigPath -PathType Leaf) {
        $projectContent = Get-Content $projectFile.FullName -Raw
        $projectXml = [xml]$projectContent

        if (Is-LibraryProject -ProjectXml $projectXml -ProjectPath $projectFile.FullName) {
            try {
                Remove-Item $appConfigPath -Force
                Write-Host "Removed app.config from library project: $($projectFile.FullName)"
            }
            catch {
                Write-Host "Error removing app.config from $($projectFile.FullName): $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Skipped non-library project: $($projectFile.FullName)" -ForegroundColor Yellow
        }
    }
}

Write-Host "Finished processing all project files"
