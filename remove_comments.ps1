$files = Get-ChildItem -Path "c:\Projectos\APP-BIBLIOTECA\app_biblioteca\lib" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    Write-Host "Processing: $($file.FullName)"
    
    $content = Get-Content $file.FullName -Raw
    
    $lines = Get-Content $file.FullName
    $newLines = @()
    
    foreach ($line in $lines) {
        if ($line -match '^\s*///') {
            continue
        }
        
        if ($line -match '^\s*//') {
            continue
        }
        
        $cleanedLine = $line -replace '\s*//.*$', ''
        
        $newLines += $cleanedLine
    }
    
    $newContent = $newLines -join "`n"
    Set-Content -Path $file.FullName -Value $newContent -NoNewline
    
    Write-Host "Cleaned: $($file.Name)"
}

Write-Host "`nAll files processed!"
