# Offline repository integrity test: Markdown local links, screenshot inventory and SVG.
# Does not require AD, network access or any domain credentials.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$docs = @(Get-ChildItem -LiteralPath $root -Filter '*.md' -Recurse -File)
$errorsFound = [System.Collections.Generic.List[string]]::new()
$checked = 0
$pattern = '!?\[[^\]]*\]\(([^)]+)\)'
foreach ($doc in $docs) {
    $content = [System.IO.File]::ReadAllText($doc.FullName)
    foreach ($match in [regex]::Matches($content, $pattern)) {
        $href = $match.Groups[1].Value.Trim()
        if ($href -match '^(https?://|mailto:|#)' -or [string]::IsNullOrWhiteSpace($href)) { continue }
        $relativePath = ($href -split '#', 2)[0].Trim()
        if (-not $relativePath) { continue }
        $checked++
        $absolutePath = [System.IO.Path]::GetFullPath((Join-Path $doc.DirectoryName $relativePath))
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            $errorsFound.Add("$($doc.FullName): missing target $href")
        }
    }
}
$images = @(Get-ChildItem -LiteralPath (Join-Path $root 'screenshots') -Filter '*.png' -File)
if ($images.Count -ne 174) {
    $errorsFound.Add("Screenshot inventory contains $($images.Count) images; expected 174.")
}
if (-not (Test-Path -LiteralPath (Join-Path $root 'diagrams/architecture.svg') -PathType Leaf)) {
    $errorsFound.Add('Missing architecture SVG.')
}
if ($errorsFound.Count -gt 0) {
    foreach ($problem in $errorsFound) { Write-Error $problem -ErrorAction Continue }
    throw "Repository integrity FAILED with $($errorsFound.Count) issue(s)."
}
Write-Host ("PASS: {0} Markdown documents, {1} local links, {2} screenshots and architecture SVG." -f
    $docs.Count, $checked, $images.Count) -ForegroundColor Green
