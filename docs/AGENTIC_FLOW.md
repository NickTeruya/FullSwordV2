# Agentic Development Flow — Full Sword V2

This document defines how the human designer, Claude chat (architect),
Claude Code (workhorse), and the Godot MCP server work together on
Full Sword V2. Read this at the start of every new chat session.

## Roles

**Human (designer)**
- Brings problems, decisions, and design intent
- Pastes prompts from chat into Claude Code
- Tests in Godot via F5
- Screenshots results and reports back to chat
- Commits via PowerShell at clear milestones

**Claude chat (architect)**
- Discusses design decisions before code is touched
- Writes tight, specific prompts for Claude Code to execute
- Diagnoses screenshots and error output
- Calls out scope creep against V2_ARCHITECTURE.md
- Recommends git commits at natural milestones
- Searches the web when current best practices matter
- Does NOT give manual click-by-click Godot editor steps unless
  MCP cannot do the work

**Claude Code (workhorse)**
- Edits .gd and .tscn files directly
- Runs PowerShell commands when asked
- Uses Godot MCP server for scene reads and edits where possible
- Reports results back to terminal; human relays to chat

**Godot MCP server**
- Provides programmatic access to scene data from Claude Code
- Can read scene tree, node properties, transforms
- Scene-edit capability is partial — when MCP cannot perform an edit,
  Claude Code falls back to editing .tscn text directly or, last
  resort, the human does it in the GUI
- **Capability set unknown at v2 start — audit at Session 1**

## The Loop

1. Chat discusses problem with human; designs solution
2. Chat writes a specific prompt for Claude Code
3. Human pastes prompt into Claude Code terminal
4. Claude Code executes and reports back in terminal
5. Human relays results to chat (screenshot or paste)
6. Human tests in Godot (F5) and screenshots/describes outcome
7. Chat diagnoses; confirms success or writes next prompt
8. On a working milestone, human runs git commit from PowerShell

## Prompt Writing Principles

- **One task per prompt.** No "do X then Y then Z."
- **Specify success conditions.** "Confirm by reading back the
  function" or "should print 'done'." Without this we cannot tell
  whether it worked.
- **Read before write.** For non-trivial changes, prompt Claude Code
  to read and report current state first, decide the change in chat,
  then prompt the write.
- **Exact paths and node paths.** No ambiguity about which file or
  node.
- **Name the file to model on.** For new files mirroring existing
  conventions, "format it like weapon.gd" beats "match conventions."
- **Verify cross-file dependencies.** When wiring code to a method
  on a file not yet read, include "confirm the method exists with
  this signature" in the prompt.
- **Maintain existing conventions.** Reference CLAUDE.md for engine
  and project constraints.

## What NOT to Do

- Chat does not give manual Godot editor steps when Claude Code + MCP
  can do the work
- Chat does not write vague prompts
- Chat does not assume Claude Code succeeded — always asks human to test
- Chat does not let a working milestone go uncommitted
- Human does not bundle multiple unrelated changes into one Claude Code
  prompt
- Human does not skip the test step after Claude Code reports success

## Debugging Discipline

- Diagnostics before tuning — instrument and measure, don't iterate
  by feel. Read actual values, math the answer.
- After 2 failed diagnostic loops on the same issue, web search before
  the 3rd attempt. Name a Plan B workaround alongside continued
  root-cause investigation — don't wait until investigation exhausts.
- Redirect diagnostic output to tmp/ files rather than terminal dumps.

## Session Discipline

- Each session has a single named goal set at the start.
- Anything that emerges mid-session is explicitly deferred unless it
  directly blocks the named goal.
- Commit at clear milestones. Restart Claude Code at each commit.
- Code commits immediately when something works. Session notes and
  doc changes bundle into a single wrap commit at session end.

## Parallel Agent Lanes

When two tasks have zero file overlap, they can run as concurrent
Claude Code threads. Identify parallelism during session planning,
not mid-execution. A work graph beats a work list.

## .tscn Authoring Rules

- **MCP save_scene is destructive on scenes instancing .glb assets.**
  Never use on any scene that instances a character or animation .glb.
  GUI Ctrl+S only for those scenes.
- **Scene Tab Collision Protocol:** close the scene tab in Godot before
  any Claude Code .tscn edit, OR right-click tab and Reload Saved Scene
  after the edit. Godot saves in-memory state on Ctrl+S and silently
  overwrites disk edits.
- **Success criterion for .tscn authoring** is not "read it back." It
  is "open in Godot editor, zero console errors, scene survives a save
  round-trip."
- **Omit uid= on new ext_resource entries.** Let Godot assign on next
  save. Invented UIDs cause missing dependency errors.

## PowerShell Conventions

- Use semicolons as command separators, not &&
- For long text blocks (session notes, file content), use a here-string
  .ps1 script — never paste long blocks as inline Claude Code commands
- After any file write via .ps1, verify with a Python read using
  explicit UTF-8 encoding. Repair mojibake before deleting the temp
  script.
- Commits from PowerShell, not via Claude Code git commands

## Session Conventions

### Code Words

**`wrap session`** — triggers the session-close ritual. Produces two
deliverables and nothing else:
1. A Claude Code prompt to append session notes to SESSION_NOTES.md
2. A startup prompt for the next chat session

No summary prose. No extra commentary. Just those two deliverables.

### Starting a New Chat Session

First message should include:
- Session number
- Status: what was last done, what's next
- Confirmation that project knowledge files are loaded

## MCP Capabilities

Audited Session 1. Godot MCP server connected with 14 tools.

### Available Tools
- **add_node** — Add a node to an existing scene
- **create_scene** — Create a new Godot scene file
- **export_mesh_library** — Export a scene as a MeshLibrary resource
- **get_debug_output** — Get current debug output and errors
- **get_godot_version** — Get the installed Godot version
- **get_project_info** — Retrieve project metadata
- **get_uid** — Get the UID for a specific file (Godot 4.4+)
- **launch_editor** — Launch the Godot editor for a project
- **list_projects** — List Godot projects in a directory
- **load_sprite** — Load a sprite into a Sprite2D node (2D only — not useful for v2)
- **run_project** — Run the Godot project and capture output
- **save_scene** — Save changes to a scene file
- **stop_project** — Stop the currently running project
- **update_project_uids** — Update UID references by resaving resources (Godot 4.4+)

### Capability Assessment
- **Can do:** Create new scenes, add nodes, save scenes, run/stop project,
  capture debug output
- **Cannot do:** Read existing scene tree, inspect node properties, update
  node properties on existing nodes
- **Fallback:** Direct .tscn text editing for all read and modify operations.
  MCP save_scene is destructive on scenes instancing .glb assets — never use
  on character/animation scenes (existing rule stands).
- **Most useful tools for v2:** get_debug_output (diagnostics), run_project +
  stop_project (automated test cycle), create_scene + add_node (scaffolding
  new scenes)