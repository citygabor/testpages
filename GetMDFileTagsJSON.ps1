# Define the root directory where you want to search for .md files
$rootDirectory = ".\"

# Create an array to store the objects
$mdObjects = @()

# Define the file extension to search for
$fileExtension = "*.md"

# Function to calculate relative path
function Get-RelativePath {
    param (
        [string]$BasePath,
        [string]$TargetPath
    )

    $basePath = Convert-Path $BasePath
    $targetPath = Convert-Path $TargetPath
    $relativePath = $targetPath.Substring($basePath.Length + 1)
    return $relativePath
}

# Function to extract tags from a Markdown file
function Get-MarkdownTags {
    param (
        [string]$FilePath
    )

    $tags = @()
    $tagContent = @()
    $inTagsSection = $false

    $fileContent = Get-Content -Path $FilePath
    foreach ($line in $fileContent) {
        if ($line -match '^\s*## Tags\s*$') {  # Match the '## Tags' section with optional leading/trailing whitespace
            $inTagsSection = $true
        } elseif ($inTagsSection) {
            if ($line -match '^#(\w+)') {
                $tags += "#" + $matches[1]
            } elseif ($line -match '^\s*$') {
                continue  # Skip empty lines
            } else {
                break  # Exit the tags section if it's not a valid tag line
            }
        }
    }

    $tagsString = $tags -join ' '

    return $tagsString
}

# Function to extract the title from a Markdown file
function Get-MarkdownTitle {
    param (
        [string]$FilePath
    )

    $title = ""
    $fileContent = Get-Content -Path $FilePath
    foreach ($line in $fileContent) {
        if ($line -match '^#\s+(.*)$') {
            $title = $matches[1].Trim()
            break
        }
    }

    return $title
}

# Get all .md files in the root directory and its subdirectories
$mdFiles = Get-ChildItem -Path $rootDirectory -Filter $fileExtension -File -Recurse

# Loop through each .md file
foreach ($file in $mdFiles) {
    # Define the path to the MD file
    $filePath = $file.FullName

    # Calculate the relative path
    $relativePath = Get-RelativePath -BasePath $rootDirectory -TargetPath $filePath

    # Calculate the directory path
    $directoryPath = [System.IO.Path]::GetDirectoryName($relativePath)

    # Extract tags and title from the Markdown file
    $tags = Get-MarkdownTags -FilePath $filePath
    $title = Get-MarkdownTitle -FilePath $filePath

    # Create a PowerShell object and add it to the array
    $mdObject = New-Object PSObject -Property @{
        Path = $directoryPath -replace '\\', '/'
        FullPath = ($directoryPath -replace '\\', '/') + "/" + $file.Name -replace ".md", ".html"
        FileName = $file.Name -replace ".md", ".html"
        Tags = $tags  # Include extracted tags
        Title = $title  # Include extracted title
    }
    $mdObjects += $mdObject
}

# Export the objects to a JSON file
$mdObjects | ConvertTo-Json | Set-Content -Path "mdFiles.json"

Write-Host "JSON file created: mdFiles.json"