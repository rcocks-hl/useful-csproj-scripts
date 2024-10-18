# Function to check if the project file already has the required PropertyGroup
function Has-RequiredPropertyGroup {
    param (
        [xml]$ProjectXml
    )

    $propertyGroups = $ProjectXml.Project.PropertyGroup
    foreach ($propertyGroup in $propertyGroups) {
        $autoGenerate = $propertyGroup.AutoGenerateBindingRedirects
        $generateOutput = $propertyGroup.GenerateBindingRedirectsOutputType
        if ($autoGenerate -eq "true") {
            return $true
        }
    }
    return $false
}

# Function to check for Output Type Exe
function Is-CorrectOutputType {
    param (
        [xml]$ProjectXml
    )

    $propertyGroups = $ProjectXml.Project.PropertyGroup
    foreach ($propertyGroup in $propertyGroups) {
        $outputType = $propertyGroup.OutputType
        $isTestProject = $propertyGroup.IsTestProject
        
        if ($isTestProject -eq "true" -or $outputType -eq "Exe") {
            return $true
        }
    }
    return $false
}

# Function to add the required PropertyGroup
function Add-RequiredPropertyGroup {
    param (
        [xml]$ProjectXml
    )

    $newPropertyGroup = $ProjectXml.CreateElement("PropertyGroup")
    
    $autoGenerate = $ProjectXml.CreateElement("AutoGenerateBindingRedirects")
    $autoGenerate.InnerText = "true"
    $newPropertyGroup.AppendChild($autoGenerate)

    $generateOutput = $ProjectXml.CreateElement("GenerateBindingRedirectsOutputType")
    $generateOutput.InnerText = "true"
    $newPropertyGroup.AppendChild($generateOutput)

    $ProjectXml.Project.AppendChild($newPropertyGroup)
}

# Get all project files in the current directory and subdirectories
$projectFiles = Get-ChildItem -Recurse -Include *.csproj,*.vbproj

foreach ($projectFile in $projectFiles) {
    $projectDir = $projectFile.DirectoryName
    $appConfigPath = Join-Path $projectDir "app.config"
    $webConfigPath = Join-Path $projectDir "web.config"

    # Check if the project has an app.config and doesn't have a web.config
    if ((Test-Path $appConfigPath -PathType Leaf) -and !(Test-Path $webConfigPath -PathType Leaf)) {
        $projectContent = Get-Content $projectFile.FullName -Raw
        $projectXml = [xml]$projectContent

        if (-not (Has-RequiredPropertyGroup -ProjectXml $projectXml) -and (Is-CorrectOutputType -ProjectXml $projectXml)) {
            Add-RequiredPropertyGroup -ProjectXml $projectXml
            $projectXml.Save($projectFile.FullName)
            Write-Host "Added binding redirects property group to $($projectFile.FullName)"
        } else {
            Write-Host "Skipping unsuitable project $($projectFile.FullName)"
        }
    } else {
        Write-Host "Skipped $($projectFile.FullName) (no app.config or has web.config)"
    }
}

Write-Host "Finished processing all project files"