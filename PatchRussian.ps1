$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $here

$pakName = "BrigandineAbyss-Windows.pak"
$relPak = Join-Path "BrigandineAbyss\Content\Paks" $pakName
$uiNames = @("z0RussianUI_P.pak", "z0RussianUI_P.ucas", "z0RussianUI_P.utoc")
$sizesFile = Join-Path $here "sizes.json"
$stockSize = 41646580
$patchedSize = $null
if (Test-Path -LiteralPath $sizesFile) {
  $sizes = Get-Content -LiteralPath $sizesFile -Raw | ConvertFrom-Json
  if ($sizes.stockBytes) { $stockSize = [int64]$sizes.stockBytes }
  if ($sizes.patchedBytes) { $patchedSize = [int64]$sizes.patchedBytes }
}

function Find-ExistingFile {
  param([string[]]$Paths)
  foreach ($p in $Paths) {
    if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) {
      return (Resolve-Path -LiteralPath $p).Path
    }
  }
  return $null
}

function Find-Pak {
  $roots = [System.Collections.Generic.List[string]]::new()
  foreach ($r in @($here, (Split-Path $here -Parent), (Get-Location).Path)) {
    if ($r -and -not $roots.Contains($r)) { $roots.Add($r) }
  }
  $candidates = foreach ($root in $roots) {
    Join-Path $root $relPak
    Join-Path $root "Content\Paks\$pakName"
    Join-Path $root "Paks\$pakName"
    Join-Path $root $pakName
  }
  $found = Find-ExistingFile $candidates
  if (-not $found) {
    throw @"
Could not find $pakName.

Put this folder inside the Steam game directory:
  steamapps\common\HPN_NPJ

Then double-click PatchRussian.bat again.
"@
  }
  return $found
}

function Find-RussianUiFiles {
  $searchDirs = @(
    $here,
    (Join-Path $here "ui"),
    (Join-Path $here "Paks")
  )
  foreach ($dir in $searchDirs) {
    if (-not $dir -or -not (Test-Path -LiteralPath $dir -PathType Container)) { continue }
    $hits = foreach ($n in $uiNames) { Join-Path $dir $n }
    $missing = $false
    foreach ($h in $hits) {
      if (-not (Test-Path -LiteralPath $h -PathType Leaf)) { $missing = $true; break }
    }
    if (-not $missing) { return $hits }
  }
  throw "z0RussianUI_P.pak / .ucas / .utoc are missing next to this script."
}

$pak = Find-Pak
$gamePaks = Split-Path $pak -Parent
$hpatchz = Find-ExistingFile @(
  (Join-Path $here "hpatchz.exe"),
  (Join-Path $here "windows64\hpatchz.exe")
)
$diff = Find-ExistingFile @(
  (Join-Path $here "BrigandineAbyss-Windows.pak.hdiff")
)
if (-not $hpatchz) { throw "hpatchz.exe is missing next to this script." }
if (-not $diff) { throw "BrigandineAbyss-Windows.pak.hdiff is missing next to this script." }

Write-Host "Pak:   $pak"
Write-Host "Patch: $diff"

$pakLen = (Get-Item -LiteralPath $pak).Length
if ($patchedSize -and $pakLen -eq $patchedSize) {
  Write-Host "Cyrillic fonts already patched; skipping font step."
} elseif ($pakLen -ne $stockSize) {
  throw @"
This $pakName is $pakLen bytes.
The Cyrillic font patch only applies to the stock Steam file ($stockSize bytes).
Use Steam 'Verify integrity of game files' so Windows.pak is restored, then run this again.
"@
} else {
  $backup = "$pak.stock.bak"
  if (-not (Test-Path -LiteralPath $backup)) {
    Write-Host "Backing up stock pak..."
    Copy-Item -LiteralPath $pak -Destination $backup
  } else {
    Write-Host "Stock backup already exists."
  }
  $outTmp = "$pak.patched.tmp"
  if (Test-Path -LiteralPath $outTmp) { Remove-Item -LiteralPath $outTmp -Force }
  Write-Host "Applying Cyrillic font patch (no game files unpacked)..."
  $old = Get-Location
  try {
    Set-Location -LiteralPath (Split-Path $hpatchz -Parent)
    $output = & $hpatchz $pak $diff $outTmp 2>&1
    $code = $LASTEXITCODE
  } finally {
    Set-Location -LiteralPath $old
  }
  if ($code -ne 0) { throw "hpatchz failed with exit $code`n$output" }
  Move-Item -LiteralPath $outTmp -Destination $pak -Force
}

Write-Host "Installing Russian UI files..."
foreach ($src in (Find-RussianUiFiles)) {
  Copy-Item -LiteralPath $src -Destination (Join-Path $gamePaks (Split-Path $src -Leaf)) -Force
  Write-Host "Installed $(Split-Path $src -Leaf)"
}

$info = Get-Item -LiteralPath $pak
Write-Host ""
Write-Host "Done. $($info.Name) is now $([int]($info.Length / 1MB)) MB."
Write-Host "Set language to Simplified Chinese — it is labeled Русский — once in Options."
Write-Host "Steam verify restores the stock font pak; run this again after a verify."
