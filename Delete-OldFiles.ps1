# Filename: Delete-OldFiles.ps1

param (
    [Parameter(Mandatory = $true)]
    [string]$CsvFilePath
)

if (-Not (Test-Path $CsvFilePath)) {
    Write-Error "CSV file not found at path: $CsvFilePath"
    exit 1
}

# Create a unique GUID for this run
$runGuid = [guid]::NewGuid().ToString()
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFileName = "Delete-OldFiles-Log_$timestamp.txt"
$logFile = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath $logFileName

Add-Content -Path $logFile -Value "`n[$(Get-Date)] Deletion Run ID: $runGuid"
Add-Content -Path $logFile -Value "Started processing..."

# Import CSV
$entries = Import-Csv -Path $CsvFilePath

foreach ($entry in $entries) {
    $folderPath = $entry.FolderPath
    $daysOld = [int]$entry.DaysOld
    $includeSubfolders = [bool]$entry.IncludeSubfolders
    $deletedCount = 0

    if (-Not (Test-Path $folderPath)) {
        $message = "[$runGuid] Folder not found: $folderPath"
        Write-Warning $message
        Add-Content -Path $logFile -Value $message
        continue
    }

    $cutoffDate = (Get-Date).AddDays(-$daysOld)
    $searchOption = if ($includeSubfolders) { '-Recurse' } else { '' }

    $files = Get-ChildItem -Path $folderPath $searchOption -File |
             Where-Object { $_.LastWriteTime -lt $cutoffDate }

    foreach ($file in $files) {
        try {
            Remove-Item -Path $file.FullName -Force
            $deletedCount++
            Add-Content -Path $logFile -Value "[$runGuid] Deleted: $($file.FullName)"
        } catch {
            $message = "[$runGuid] Failed to delete: $($file.FullName) - $($_.Exception.Message)"
            Write-Warning $message
            Add-Content -Path $logFile -Value $message
        }
    }

    $summaryMessage = "[$runGuid] Folder: $folderPath | Files Deleted: $deletedCount"
    Write-Host $summaryMessage
    Add-Content -Path $logFile -Value $summaryMessage
}

Add-Content -Path $logFile -Value "[$(Get-Date)] Run ID $runGuid completed."
