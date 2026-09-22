#requires -Version 5.1
# Sync the dashcast-netease fork from the main project, so the fork carries only its two
# documented divergences instead of drifting a whole file at a time.
#
# Why this exists: the fork used to be maintained by hand-copying files, and its own class
# comment claimed "only onCreate differs". That claim had already gone false -- the main
# CastActivity had grown 222 lines of UI wiring the fork never received -- so every sync
# meant re-diffing everything. This script makes the claim mechanically true:
#   main file --(package prefix)--> fork file, except CastActivity, where two reviewable
#   fragments from apk/fork/ are spliced in (class javadoc + onCreate) and one policy
#   method is replaced in place (keepWatchAfterTarget -> false).
#
# Since the 3.0 architecture there is no shared out-of-tree agent jar any more: the
# uid-2000 privileged process is spawned via CLASSPATH=<this APK> and its code lives in
# this package's own dex. That inverts the old renaming rule -- every cross-process name
# (Binder descriptor, broadcast action, extra key, app_process entry class, nice name)
# is internal to ONE app, so ALL of them get the fork prefix and two installed apps can
# never talk to each other's privileged process.
#
# ASCII only: Windows PowerShell 5.1 reads .ps1 as ANSI unless it has a BOM.
param(
    # Default layout: this repo and a clone of byd-dashboard sit side by side.
    #   <anywhere>\byd-dashboard\apk        <- Main   (the public main project)
    #   <anywhere>\byd-dashboard-netease\   <- this repo; the fork is generated into apk\
    [string]$Main = '',
    [string]$Fork = ''
)
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Main) { $Main = Join-Path (Split-Path -Parent $repoRoot) 'byd-dashboard\apk' }
if (-not $Fork) { $Fork = Join-Path $repoRoot 'apk' }

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding $false

function Read-Text([string]$p) {
    return [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
}
function Write-Text([string]$p, [string]$t) {
    $dir = Split-Path -Parent $p
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($p, $t, $utf8)
}

function Convert-Package([string]$t) {
    # One rule, applied everywhere: the token com.byd.dashcast that is not already
    # namespaced under .netease gets the prefix. This covers package declarations,
    # imports, inline qualified names (e.g. com.byd.dashcast.ShellChannel.get() in
    # AdbBootstrap) and the cross-process string literals (Binder descriptor, broadcast
    # action, extra keys, the app_process entry class, APP_PACKAGE -> NICE_NAME) in one
    # go. The negative lookahead makes it idempotent, so nothing can double-prefix and
    # re-running the sync cannot drift.
    # (An earlier version had per-context rules -- package/import/literal -- and missed
    # the inline qualified name while double-prefixing the adb imports. One total rule
    # is smaller and cannot miss a context.)
    return ($t -replace 'com\.byd\.dashcast(?!\.netease)', 'com.byd.dashcast.netease')
}

# Index of the '}' that closes the block opened at $openBrace, skipping braces that live in
# string / char literals or comments. A plain regex cannot do this and the fork's two
# fragments must land on exact boundaries, so match properly.
function Get-BodyEnd([string]$text, [int]$openBrace) {
    $depth = 0; $i = $openBrace; $n = $text.Length
    $inStr = $false; $inChr = $false; $inLine = $false; $inBlk = $false
    $BS = [char]92; $DQ = [char]34; $SQ = [char]39; $SL = [char]47; $ST = [char]42
    $LB = [char]123; $RB = [char]125
    while ($i -lt $n) {
        $c = $text[$i]
        $d = if ($i + 1 -lt $n) { $text[$i + 1] } else { [char]0 }
        if ($inLine) { if ($c -eq "`n") { $inLine = $false } }
        elseif ($inBlk) { if ($c -eq $ST -and $d -eq $SL) { $inBlk = $false; $i++ } }
        elseif ($inStr) { if ($c -eq $BS) { $i++ } elseif ($c -eq $DQ) { $inStr = $false } }
        elseif ($inChr) { if ($c -eq $BS) { $i++ } elseif ($c -eq $SQ) { $inChr = $false } }
        else {
            if ($c -eq $SL -and $d -eq $SL) { $inLine = $true; $i++ }
            elseif ($c -eq $SL -and $d -eq $ST) { $inBlk = $true; $i++ }
            elseif ($c -eq $DQ) { $inStr = $true }
            elseif ($c -eq $SQ) { $inChr = $true }
            elseif ($c -eq $LB) { $depth++ }
            elseif ($c -eq $RB) { $depth--; if ($depth -eq 0) { return $i } }
        }
        $i++
    }
    return -1
}

Write-Output '--- stale files from the 1.x architecture ---'
# The fork on disk may still carry files that no longer have a main-project counterpart.
# Leaving them in place would make "what does the fork ship" a question answered by
# archaeology instead of by the main tree, so remove them explicitly.
foreach ($stale in @(
        (Join-Path $Fork 'src\com\byd\dashcast\netease\adb\AgentLauncher.java'),
        (Join-Path $Fork 'assets\dashcast-agent.jar'),
        (Join-Path $Fork 'assets\adb_identity.pk8'),
        (Join-Path $Fork 'debug.keystore'))) {
    if (Test-Path $stale) {
        Remove-Item $stale -Force
        Write-Output "  removed $(Split-Path -Leaf $stale)"
    }
}

Write-Output '--- java: verbatim copy + package prefix ---'
$plain = @(
    'AppRepo.java', 'AutoCast.java', 'CarAccount.java', 'CastActivity.java' , 'DashboardEye.java',
    'DashboardSession.java', 'Favorites.java', 'GuideActivity.java', 'InjectClient.java',
    'PrivilegedClient.java', 'ShellChannel.java'
)
# CastActivity.java is listed only so a missing file fails loudly here; it is overwritten
# by the splice step below.
foreach ($f in $plain) {
    $src = Join-Path $Main "src\com\byd\dashcast\$f"
    $dst = Join-Path $Fork "src\com\byd\dashcast\netease\$f"
    Write-Text $dst (Convert-Package (Read-Text $src))
    Write-Output "  $f"
}
foreach ($f in @('AdbBootstrap.java', 'AdbClient.java', 'AdbKeyStore.java', 'BootReceiver.java')) {
    $src = Join-Path $Main "src\com\byd\dashcast\adb\$f"
    $dst = Join-Path $Fork "src\com\byd\dashcast\netease\adb\$f"
    Write-Text $dst (Convert-Package (Read-Text $src))
    Write-Output "  adb\$f"
}
foreach ($f in @('InputInjector.java', 'PreviewDisplay.java', 'PrivilegedProcess.java', 'PrivilegedProtocol.java')) {
    $src = Join-Path $Main "src\com\byd\dashcast\privileged\$f"
    $dst = Join-Path $Fork "src\com\byd\dashcast\netease\privileged\$f"
    Write-Text $dst (Convert-Package (Read-Text $src))
    Write-Output "  privileged\$f"
}

Write-Output '--- CastActivity: main copy + the fork''s three fragments ---'
$text = Convert-Package (Read-Text (Join-Path $Main 'src\com\byd\dashcast\CastActivity.java'))

$cls = 'public final class CastActivity extends Activity'
$ci = $text.IndexOf($cls)
if ($ci -lt 0) { throw 'anchor not found: CastActivity class declaration' }
$docStart = $text.LastIndexOf('/**', $ci)
if ($docStart -lt 0) { throw 'anchor not found: CastActivity class javadoc' }
$doc = (Read-Text (Join-Path $Fork 'fork\CastActivity.doc.txt')).TrimEnd("`r", "`n")
$text = $text.Substring(0, $docStart) + $doc + "`n" + $text.Substring($ci)

$sig = 'protected void onCreate(Bundle savedInstanceState)'
$si = $text.IndexOf($sig)
if ($si -lt 0) { throw 'anchor not found: onCreate signature' }
$brace = $text.IndexOf('{', $si)
if ($brace -lt 0) { throw 'anchor not found: onCreate opening brace' }
$end = Get-BodyEnd $text $brace
if ($end -lt 0) { throw 'brace matching failed for onCreate' }
$ov = $text.LastIndexOf('@Override', $si)
if ($ov -lt 0) { throw 'anchor not found: @Override above onCreate' }
$start = $ov
while ($start -gt 0 -and ($text[$start - 1] -eq ' ' -or $text[$start - 1] -eq "`t")) { $start-- }
$onCreate = (Read-Text (Join-Path $Fork 'fork\CastActivity.onCreate.txt')).TrimEnd("`r", "`n")
$text = $text.Substring(0, $start) + $onCreate + $text.Substring($end + 1)

# The fork's overrides REPLACE the main project's policy methods in place. Appending them
# instead would leave both definitions in the file (duplicate method -> javac error), and
# replacing in place also keeps whatever ordering the main project has.
$overrideSrc = Read-Text (Join-Path $Fork 'fork\CastActivity.overrides.txt')
$replacements = @('keepWatchAfterTarget')
foreach ($name in $replacements) {
    $sig = "protected boolean $name()"
    $mi = $text.IndexOf($sig)
    if ($mi -lt 0) { throw "anchor not found in the main project: $name" }
    $mDoc = $text.LastIndexOf('/**', $mi)
    if ($mDoc -lt 0) { throw "anchor not found: javadoc above $name" }
    $mBrace = $text.IndexOf('{', $mi)
    $mEnd = Get-BodyEnd $text $mBrace
    if ($mEnd -lt 0) { throw "brace matching failed for $name" }
    # Trim the blank line the removed block leaves behind so the file does not drift apart.
    while ($mDoc -gt 0 -and ($text[$mDoc - 1] -eq "`n" -or $text[$mDoc - 1] -eq ' ')) { $mDoc-- }
    if ($mDoc -gt 0) { $mDoc++ }
    $block = $overrideSrc.TrimEnd("`r", "`n")
    $text = $text.Substring(0, $mDoc) + $block + $text.Substring($mEnd + 1)
}
Write-Text (Join-Path $Fork 'src\com\byd\dashcast\netease\CastActivity.java') $text
Write-Output '  CastActivity.java'

Write-Output '--- res: verbatim copy, then the fork''s app_name ---'
# The old script rewrote only strings.xml and silently relied on layouts hand-copied once.
# Copy the whole tree so the fork's res is exactly the main project's res.
Get-ChildItem (Join-Path $Main 'res') -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring((Join-Path $Main 'res').Length + 1)
    $dst = Join-Path (Join-Path $Fork 'res') $rel
    Write-Text $dst (Read-Text $_.FullName)
    Write-Output "  res\$rel"
}
$st = Read-Text (Join-Path $Main 'res\values\strings.xml')
# The fork's own app label lives in a fragment file, NOT as a literal in this script:
# Windows PowerShell 5.1 decodes a BOM-less .ps1 as ANSI, so a Chinese literal here would
# be silently mangled into mojibake before it ever reached the output. Read it as UTF-8.
$appName = (Read-Text (Join-Path $Fork 'fork\app_name.txt')).Trim()
if ($appName.Length -eq 0) { throw 'fork\app_name.txt is empty' }
$m = [regex]::Match($st, '<string name="app_name">[^<]*</string>')
if (-not $m.Success) { throw 'anchor not found: app_name string' }
$want = '<string name="app_name">' + $appName + '</string>'
$st = $st.Substring(0, $m.Index) + $want + $st.Substring($m.Index + $m.Length)
Write-Text (Join-Path $Fork 'res\values\strings.xml') $st
Write-Output '  res\values\strings.xml (app_name replaced)'

Write-Output '--- manifest / build.ps1 ---'
$mf = Read-Text (Join-Path $Main 'AndroidManifest.xml')
$mainVn = [regex]::Match($mf, 'android:versionName="([^"]*)"').Groups[1].Value
if ($mainVn.Length -eq 0) { throw 'anchor not found: main versionName' }
# versionCode intentionally stays identical to the main project: the two apps are different
# packages, and versionName is the single source of truth for "which line is this".
$mf = $mf -replace 'package="com\.byd\.dashcast"', 'package="com.byd.dashcast.netease"'
$mf = $mf -replace 'com\.byd\.dashcast\.adb\.BootReceiver', 'com.byd.dashcast.netease.adb.BootReceiver'
$mf = $mf -replace 'android:versionName="[^"]*"', ('android:versionName="' + $mainVn + '-netease"')
Write-Text (Join-Path $Fork 'AndroidManifest.xml') $mf
Write-Output "  AndroidManifest.xml (versionName $mainVn-netease)"

$bp = Read-Text (Join-Path $Main 'build.ps1')
$bp = $bp -replace "'dashcast\.apk'", "'dashcast-netease.apk'"
# build.ps1 carries Chinese comments and is parsed by Windows PowerShell 5.1, which decodes
# a BOM-less .ps1 as ANSI -- the mojibake then shifts string boundaries and the file stops
# parsing (observed: the '<' operator is reserved). The main project's copy keeps a BOM,
# so the fork's copy must too.
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText((Join-Path $Fork 'build.ps1'), $bp, $utf8Bom)
Write-Output '  build.ps1 (output renamed, BOM kept; nothing else diverges)'

Write-Output '--- verify ---'
# U+FFFD anywhere means some source string was decoded with the wrong encoding. That is
# exactly how a Chinese literal in a BOM-less .ps1 turns into mojibake, and it is invisible
# in a directory listing -- so assert on it instead of trusting the run to have gone well.
$corrupt = 0
foreach ($f in (Get-ChildItem (Join-Path $Fork 'src') -Recurse -Filter *.java)) {
    if ((Read-Text $f.FullName).Contains([char]0xFFFD)) {
        Write-Output "  CORRUPT $($f.Name) contains U+FFFD"
        $corrupt++
    }
}
$stCheck = Read-Text (Join-Path $Fork 'res\values\strings.xml')
if (-not $stCheck.Contains($want)) {
    Write-Output '  CORRUPT res\values\strings.xml: app_name did not round-trip'
    $corrupt++
}
if ($corrupt -gt 0) { Write-Output "FAILED: $corrupt file(s) decoded with the wrong encoding"; exit 1 }
Write-Output '  OK   no encoding corruption'

Write-Output '--- verify: every cross-process name must carry the fork prefix ---'
# In the 1.x era four names had to stay UNRENAMED because a shared agent jar spoke them.
# Since 3.0 the privileged process is spawned from this APK and every protocol constant is
# copied from the same source file, so the invariant flipped: ANY remaining com.byd.dashcast
# token (declaration, import, inline name or string literal) that did NOT get the prefix
# would mean the rename missed a spot -- and a missed spot is how two installed apps start
# talking to each other's privileged process. Assert on the total rule, not a subset.
$leak = Get-ChildItem (Join-Path $Fork 'src') -Recurse -Filter *.java |
    Select-String -Pattern 'com\.byd\.dashcast(?!\.netease)'
if ($leak) {
    foreach ($l in $leak) { Write-Output "  LEAK $($l.Filename):$($l.LineNumber): $($l.Line.Trim())" }
    Write-Output 'FAILED: unrenamed com.byd.dashcast token(s) in the fork'; exit 1
}
Write-Output '  OK   every com.byd.dashcast token carries the .netease prefix'

# And the renamed tokens the privileged channel actually speaks must all be present.
$need = @(
    '"com.byd.dashcast.netease.privileged.PrivilegedProcess"',
    '"com.byd.dashcast.netease.privileged.Channel"',
    '"com.byd.dashcast.netease.PRIVILEGED_READY"',
    '"com.byd.dashcast.netease"'
)
$bad = 0
$allForkJava = Get-ChildItem (Join-Path $Fork 'src') -Recurse -Filter *.java | ForEach-Object { $_.FullName }
foreach ($token in $need) {
    $hit = Select-String -SimpleMatch $token -Path $allForkJava -List
    if ($hit) { Write-Output "  OK   $token" } else { Write-Output "  MISS $token"; $bad++ }
}
if ($bad -gt 0) { Write-Output "FAILED: $bad renamed token(s) missing"; exit 1 }

# The one behavioural divergence must actually be in the generated file.
$ca = Read-Text (Join-Path $Fork 'src\com\byd\dashcast\netease\CastActivity.java')
if ($ca -notmatch '(?s)keepWatchAfterTarget\(\)\s*\{\s*return false;') {
    Write-Output 'FAILED: keepWatchAfterTarget does not return false in the fork'; exit 1
}
Write-Output '  OK   keepWatchAfterTarget() returns false'

Write-Output 'DONE'
