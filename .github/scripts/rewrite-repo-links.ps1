param(
  [string]$SourceRepo = "NoM0Re/WoW-3.3.5a-Addons",
  [string]$TargetRepo = "NoM0Re/WoW-3.3.5a-Addons2"
)

$ErrorActionPreference = "Stop"

$sourceRepoLower = $SourceRepo.ToLowerInvariant()
$targetRepoLower = $TargetRepo.ToLowerInvariant()
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
  return [regex]::Replace($Content, $pattern, $To)
}

$trackedFiles = git ls-files
$rewrittenFiles = 0

foreach ($file in $trackedFiles) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
    continue
  }

  if ($file -eq ".github" -or $file.StartsWith(".github/") -or $file.StartsWith(".github\")) {
    continue
  }

  $extension = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
  if ($extension -in @(".zip", ".rar", ".7z", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".pdf")) {
    continue
  }

  $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
  $updated = Convert-ExactRepoLink -Content $content -From $SourceRepo -To $TargetRepo
  $updated = Convert-ExactRepoLink -Content $updated -From $sourceRepoLower -To $targetRepoLower
  $updated = Convert-ExactRepoLink -Content $updated -From $sourcePages -To $targetPages

  if ($updated -ne $content) {
    [System.IO.File]::WriteAllText($file, $updated, $utf8NoBom)
    $rewrittenFiles++
  }
}

Write-Host "Rewritten files: $rewrittenFiles"
