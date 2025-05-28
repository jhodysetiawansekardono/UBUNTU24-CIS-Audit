# Save as add_meta_key_to_all.ps1
param(
    [string]$MetaKey = "host_hostname",
    [string]$MetaValue = "{{ .Vars.os_hostname }}"
)

$sections = 1..7 | ForEach-Object { "section_$_" }
foreach ($section in $sections) {
    Get-ChildItem -Path ".\$section" -Recurse -Filter *.yml | ForEach-Object {
        $file = $_.FullName
        $content = Get-Content $file
        $newContent = @()
        $inMeta = $false
        $keyAdded = $false
        foreach ($i in 0..($content.Count-1)) {
            $line = $content[$i]
            # Detect start of a meta block
            if ($line -match '^\s*meta:\s*$') {
                $inMeta = $true
                $keyAdded = $false
                $newContent += $line
                continue
            }
            # If inside meta block and key not yet added
            if ($inMeta -and -not $keyAdded) {
                # Check if key already present
                $keyPattern = "^\s*${MetaKey}:"
                if ($line -match $keyPattern) {
                    $keyAdded = $true
                } elseif ($line -match '^\s*\w+:') {
                    # Use the same indentation as the next key
                    $indentMatch = $line -match '^(\s*)\w+:'
                    $indent = $matches[1]
                    $newContent += "$indent$($MetaKey): $MetaValue"
                    $keyAdded = $true
                }
            }
            $newContent += $line
            # End meta block if next block starts (not indented or empty line)
            if ($inMeta -and ($line -match '^\S' -or $line -eq '')) {
                $inMeta = $false
            }
        }
        # Write only if changed
        if ($newContent -ne $content) {
            Set-Content $file $newContent
            Write-Host "Updated $file"
        }
    }
}