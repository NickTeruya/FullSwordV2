# start-session.ps1
# Full Sword V2 — session bootstrap.
# Run via the `fullsword` function in your PowerShell profile, or directly.

$ProjectRoot = "C:\Users\nickw\Documents\FullSwordV2"

# Verify project root exists
if (-not (Test-Path $ProjectRoot)) {
    Write-Host "ERROR: Project root not found at $ProjectRoot" -ForegroundColor Red
    Write-Host "Edit start-session.ps1 to update the `$ProjectRoot path." -ForegroundColor Red
    exit 1
}

Set-Location $ProjectRoot

# Read next session number from SESSION_STATE.md — authoritative, set deliberately each wrap.
# Fail loud if the file or the field is missing; a wrong number is worse than a halt.
$StateFile = "docs/sessions/SESSION_STATE.md"
if (-not (Test-Path $StateFile)) {
    Write-Host "ERROR: $StateFile not found. Cannot determine session number." -ForegroundColor Red
    exit 1
}
$nextLine = Select-String -Path $StateFile -Pattern "^Next session:\s*(\d+)" | Select-Object -First 1
if (-not $nextLine) {
    Write-Host "ERROR: 'Next session: N' line not found in $StateFile." -ForegroundColor Red
    exit 1
}
$SessionNumber = [int]$nextLine.Matches[0].Groups[1].Value

# Build the chat bootstrap message
$BootstrapMessage = @"
Continuing Full Sword V2. Session $SessionNumber.

Read these from Project Knowledge first and confirm access:
- CLAUDE.md
- docs/V2_ARCHITECTURE.md
- docs/AGENTIC_FLOW.md
- docs/sessions/SESSION_NOTES.md
- docs/ASSET_AUDIT.md

Status: [FILL IN — what was last done, what's next]

Workflow ground rules per docs/AGENTIC_FLOW.md:
- Claude Code prompt is default for every change; GUI fallback only when MCP can't do the task.
- Web search after 2 failed diagnostic loops.
- Diagnostics before tuning — instrument and measure, don't iterate by feel.
- Read before write for non-trivial changes.

Where should we start?
"@

# Copy to clipboard
$BootstrapMessage | Set-Clipboard

# Banner + next steps
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host " Full Sword V2  --  Session $SessionNumber" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Project root: $ProjectRoot" -ForegroundColor Gray
Write-Host ""
Write-Host " [OK] Chat bootstrap copied to clipboard" -ForegroundColor Green
Write-Host "      Paste into Claude.ai project chat to start the session." -ForegroundColor Gray
Write-Host "      Fill in the [STATUS] line first." -ForegroundColor Yellow
Write-Host ""
Write-Host " Next steps:" -ForegroundColor Cyan
Write-Host "   1. Open Godot, load this project" -ForegroundColor Gray
Write-Host "      Verify: Editor Settings -> Script auto-reload is OFF" -ForegroundColor Gray
Write-Host "   2. Paste bootstrap (already on clipboard) into Claude.ai chat" -ForegroundColor Gray
Write-Host "   3. Run 'claude' below to start Claude Code" -ForegroundColor Gray
Write-Host "      Verify with /mcp that Godot MCP server is connected" -ForegroundColor Gray
Write-Host ""
Write-Host " If MCP server is missing or env vars are gone, see docs/sessions/STARTUP.md" -ForegroundColor Yellow
Write-Host ""
