# Full Sword V2 -- Startup & Recovery

How to start a session, and how to fix things when the setup breaks.

## Quick Start (every session)

    fullsword2

That's it, after one-time setup below. The function cd's to the project,
copies a chat bootstrap message to your clipboard, and tells you what to
do next.

If fullsword2 is not defined yet, see First-time setup below.

## What "starting a session" actually involves

Three things running in parallel during a working session:

1. Godot editor -- open the project. Verify script auto-reload is OFF
   (Editor Settings -> Text Editor -> Files -> Auto Reload Scripts on
   External Change). Auto-reload races with Claude Code edits and
   produces silent bugs.

2. Claude Code in Windows Terminal -- run claude from the project root.
   Verify the Godot MCP server is connected with /mcp.

3. Claude.ai chat in browser -- paste the bootstrap message
   (clipboard from fullsword2), fill in the session status line first.

Do all three at the start of every work block.

## First-time setup (do once)

### 1. Add the fullsword2 function to your PowerShell profile

In Windows Terminal, run:

    notepad $PROFILE

If it says the file does not exist, accept the prompt to create it. Add:

    function fullsword2 {
        & "C:\Users\nickw\Documents\FullSwordV2\start-session.ps1"
        Set-Location "C:\Users\nickw\Documents\FullSwordV2"
    }

Save, close, open a new terminal tab, run fullsword2. You should see
the session banner and "copied to clipboard."

### 2. Verify start-session.ps1 exists

    Test-Path "C:\Users\nickw\Documents\FullSwordV2\start-session.ps1"

If False, copy from v1 and update the project root path:

    Copy-Item "C:\Users\nickw\Documents\FullSwordDemo\start-session.ps1" "C:\Users\nickw\Documents\FullSwordV2\start-session.ps1"
    notepad "C:\Users\nickw\Documents\FullSwordV2\start-session.ps1"

Change the ProjectRoot line from FullSwordDemo to FullSwordV2 and save.

### 3. Verify .mcp.json exists

The Godot MCP server is configured via a .mcp.json file at the project
root. The claude mcp add command is broken on current Claude Code
versions (fails with "missing required argument 'commandOrUrl'") --
do not attempt to use it. Always configure MCP via .mcp.json directly.

    Test-Path "C:\Users\nickw\Documents\FullSwordV2\.mcp.json"

If False, create it -- see Recovery: MCP server missing below.

### 4. Verify MCP connection

Start Claude Code and run /mcp. You should see:

    Project MCPs (C:\Users\nickw\Documents\FullSwordV2\.mcp.json)
    godot . connected . 14 tools

If godot is missing, exit Claude Code completely and restart -- .mcp.json
is only read on startup.

### 5. Create the Claude.ai project (first session only)

Create a new project at claude.ai. Upload these files to project
knowledge:

    CLAUDE.md
    docs/AGENTIC_FLOW.md
    SESSION_NOTES.md
    docs/ASSET_AUDIT.md
    docs/V2_ARCHITECTURE.md
    docs/ANIMATION_PIPELINE.md
    docs/COMBAT_FEEL.md
    docs/COMBAT_CONTRACT.md

Re-upload SESSION_NOTES.md after every session wrap -- it is the only
file that changes regularly. The others only need re-uploading if edited.

## Pre-session checklist

    [ ] Godot is open with the project loaded
    [ ] Editor Settings -> Script auto-reload is OFF
    [ ] Claude Code is running from project root (cd FullSwordV2, then claude)
    [ ] /mcp shows godot . connected
    [ ] Claude.ai project has current SESSION_NOTES.md uploaded
    [ ] Bootstrap message pasted with status line filled in

The last two are the only ones that require thinking. The rest are
mechanical -- the checklist exists so you do not skip them.

## Key paths (this machine)

    Project root:      C:\Users\nickw\Documents\FullSwordV2
    Godot executable:  C:\Users\nickw\Desktop\Game Dev\Godot_v4.6.3-stable_win64.exe
    godot-mcp server:  C:\Users\nickw\Documents\godot-mcp\build\index.js
    Bootstrap script:  C:\Users\nickw\Documents\FullSwordV2\start-session.ps1
    v1 reference:      C:\Users\nickw\Documents\FullSwordDemo

## Recovery

### MCP server missing or not connected

Symptoms: /mcp shows no godot entry, or godot shows but calls fail
with env var errors.

Step 1 -- verify .mcp.json exists and contains valid JSON:

    Get-Content "C:\Users\nickw\Documents\FullSwordV2\.mcp.json"

Step 2 -- if missing or corrupt, recreate it. Run this in PowerShell:

    $config = @'
    {
      "mcpServers": {
        "godot": {
          "type": "stdio",
          "command": "node",
          "args": [
            "C:\\Users\\nickw\\Documents\\godot-mcp\\build\\index.js"
          ],
          "env": {
            "GODOT_PATH": "C:\\Users\\nickw\\Desktop\\Game Dev\\Godot_v4.6.3-stable_win64.exe",
            "GODOT_PROJECT_PATH": "C:\\Users\\nickw\\Documents\\FullSwordV2"
          }
        }
      }
    }
    '@
    Set-Content -Path "C:\Users\nickw\Documents\FullSwordV2\.mcp.json" -Value $config -Encoding UTF8

Step 3 -- exit Claude Code completely and restart from project root:

    cd C:\Users\nickw\Documents\FullSwordV2
    claude

Step 4 -- run /mcp to confirm godot shows as connected.

### start-session.ps1 missing

    Copy-Item "C:\Users\nickw\Documents\FullSwordDemo\start-session.ps1" "C:\Users\nickw\Documents\FullSwordV2\start-session.ps1"
    notepad "C:\Users\nickw\Documents\FullSwordV2\start-session.ps1"

Update ProjectRoot to C:\Users\nickw\Documents\FullSwordV2 and save.

### Claude Code auto-update failed ("claude.exe in use")

Not a blocker. Continue working. To clear it:

1. Note your session number
2. Exit Claude Code (/exit)
3. Close any VS Code windows with the Claude extension running
4. Run fullsword2 -- the update applies on relaunch

### Need to restart Claude Code mid-session

Claude Code has no memory across restarts. Before exiting:

1. Ask Claude Code to summarize what it just did
2. Exit (/exit), restart (fullsword2, then claude)
3. First prompt: "We're mid-Session N. Just finished X. Next task is Y.
   Read CLAUDE.md and AGENTIC_FLOW.md first."

The Claude.ai chat side does NOT need to restart -- it keeps the full
conversation. Only Claude Code's terminal state is lost.

### Need to restart Claude.ai chat mid-session

Open a new chat in the same Claude.ai project. Project files reload
automatically. Paste a fresh bootstrap with status reflecting where
you actually are.

### File encoding corruption (PowerShell wrote UTF-16 BOM)

Symptoms: Godot cannot load a file; it looks fine in a text editor
but has weird leading bytes.

Always write files with explicit UTF-8:

    Set-Content -Path "file.gd" -Value $content -Encoding UTF8

For here-string .ps1 scripts writing to SESSION_NOTES.md: always
verify with a Python read after the write and repair mojibake before
deleting the temp script. Em dashes and smart quotes are the usual
culprits. Use plain ASCII hyphens (--) in here-string content to avoid
the repair step entirely.

Verification pattern:

    python -c "
    with open('SESSION_NOTES.md', encoding='utf-8') as f:
        content = f.read()
    bad = content.count('\u00e2')
    print(f'Mojibake sequences found: {bad}')
    "

### Godot won't load a scene Claude Code just authored as text

Symptoms: console errors about missing resources, malformed sections,
or invalid UIDs on scene open.

"Read it back" is not sufficient verification for .tscn authoring.
The only real test is: open in editor -> no console errors -> save
round-trip -> still no errors.

Fix:
1. Note exactly what error Godot reports
2. Paste it back into chat -- let architect layer decide the fix
3. If the file is small, hand-fixing in Godot is often faster than
   another Claude Code round trip

## Useful commands reference

Claude Code:
    /mcp       -- list connected MCP servers and tool counts
    /status    -- token usage, session state
    /exit      -- close cleanly
    /btw       -- side question without interrupting current work

Git from project root:
    git status               -- what has changed
    git log --oneline -10    -- recent history
    git tag                  -- list milestone tags
    q                        -- exit git pager when stuck

Godot editor:
    F5    -- run project
    F6    -- run current scene
    F1    -- class documentation for selected node or type

## When in doubt

Diagnostic hierarchy from AGENTIC_FLOW.md:

1. Two failed attempts on the same issue -> web search before the third
2. Diagnostic prints before tuning, always
3. Still stuck -> name the constraint clearly in chat before proposing
   workarounds

Then update this file with the new failure mode and the fix. The doc
gets better with use -- that is the point.