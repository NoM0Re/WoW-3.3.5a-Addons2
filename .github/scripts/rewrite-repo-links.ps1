param(
  [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
  [string]$SourceRepo = "NoM0Re/WoW-3.3.5a-Addons",
  [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
  [string]$TargetRepo = "NoM0Re/WoW-3.3.5a-Addons2"
)

$ErrorActionPreference = "Stop"

$sourcePages = "$($SourceRepo.Split('/')[0].ToLowerInvariant()).github.io/$($SourceRepo.Split('/')[1])"
$targetPages = "$($TargetRepo.Split('/')[0].ToLowerInvariant()).github.io/$($TargetRepo.Split('/')[1])"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Convert-ExactRepoLink {
  param(
    [string]$Content,
    [string]$From,
    [string]$To
  )

  $pattern = [regex]::Escape($From) + "(?![A-Za-z0-9._-])"
  $options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
  return [regex]::Replace($Content, $pattern, $To, $options)
}

$trackedOutput = git ls-files -z
if ($LASTEXITCODE -ne 0) {
  throw "Could not list tracked files. Run this script from the repository root."
}
$trackedFiles = ($trackedOutput -join "`n").Split([char]0, [System.StringSplitOptions]::RemoveEmptyEntries)
# Include plugin guides, website assets and the description-sync script.
# Never decode downloaded AddOns, screenshots or other binary files as text.
$textExtensions = @(".md", ".json", ".html", ".css", ".js", ".cjs", ".mjs", ".yml", ".yaml", ".svg", ".txt", ".xml", ".lua", ".toc", ".ini", ".cfg", ".ps1", ".py", ".toml")
$rewrittenFiles = 0

foreach ($file in $trackedFiles) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
    continue
  }

  if ($file -eq ".github" -or $file.StartsWith(".github/") -or $file.StartsWith(".github\")) {
    continue
  }

  $extension = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
  if ($extension -notin $textExtensions) {
    continue
  }

  $filePath = Join-Path (Get-Location).Path $file
  $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
  $updated = Convert-ExactRepoLink -Content $content -From $SourceRepo -To $TargetRepo
  $updated = Convert-ExactRepoLink -Content $updated -From $sourcePages -To $targetPages

  if ($updated -ne $content) {
    [System.IO.File]::WriteAllText($filePath, $updated, $utf8NoBom)
    $rewrittenFiles++
  }
}

Write-Host "Rewritten files: $rewrittenFiles"
