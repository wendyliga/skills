---
name: extract-xcode-skills
description: "Extract Xcode 27's built-in agentic skills (spread across IDEIntelligenceChat.framework and the local Xcode assistant cache) into standalone SKILL.md packages usable by external agents like Claude Code or Codex. Use when the user wants to pull, port, sync, or mirror Xcode's native AI skills (e.g. swiftui-specialist, uikit-app-modernization, accessibility-voiceover-specialist) out of Xcode.app and into another agent's skill directory."
---

# Extract Xcode Skills

## Overview

Xcode 27's built-in agentic skills are spread across two different mechanisms — a given skill lives in exactly one:

- **A. `IDEIntelligenceChat.framework/.../Resources/`** — flat files: `<skill>.idechatprompttemplate` (the `SKILL.md` body) + `<skill>-ref-*.md.packaged` (the `references/*.md` files, prefixed with the skill name). e.g. `swiftui-specialist`, `swiftui-whats-new-27`, `uikit-app-modernization`, `audit-xcode-security-settings`, `adopt-c-bounds-safety`.
- **B. Not statically bundled in Xcode.app at all.** Staged at runtime by the `IDEIntelligenceAgents` daemon into a per-build-number temp dir, and mirrored into a persistent local cache once used: `~/Library/Developer/Xcode/CodingAssistant/codex/skills/__xcode/<skill>/` — already plain `SKILL.md` + `references/*.md`, just copy as-is. e.g. `accessibility-dynamic-type-specialist`, `accessibility-voiceover-specialist`, `device-interaction`, `modernize-tests`, and also `translation`/`translation-coordinator` if they've been cached locally. This source only exists locally after Xcode's assistant has been used at least once — if a skill is missing from here, open a chat in Xcode, reference that skill by name, then retry.

Both are plain UTF-8 markdown despite the `.packaged`/`.idechatprompttemplate` extensions — extraction is discovery + copy + rename, no decoding required. [scripts/extract-xcode-skill.sh](scripts/extract-xcode-skill.sh) tries A, then B for each skill name and reports which source it used.

**Known limitation:** `translation-coordinator` ships with no YAML frontmatter (`name`/`description`) and its body calls Xcode-native tools (`LocalizationPlanner`, `StringCatalogRead`) that don't exist outside Xcode. It extracts, but it won't register as a usable skill for an external agent and isn't functional there. Flag this to the user rather than fabricating frontmatter or rewriting the tool calls.

## When To Invoke

- Use when the user wants to pull, port, sync, or mirror Xcode's built-in AI skills into another agent.
- Use when the user names a specific Xcode skill (e.g. "swiftui-specialist") to extract.
- Do not invoke for authoring brand-new skills from scratch, or for editing already-extracted skill content — that's regular skill-authoring work, not extraction.

## Install Layout

- Canonical store: every extracted skill is copied to `~/.agents/skills/<skill-name>/` (SKILL.md + `references/`). This is the default `dest root` the script writes to and the shared source of truth across agents.
- Per-agent visibility: the canonical copy is made visible to a specific agent via a symlink, not a second copy:
  - Claude Code: `~/.claude/skills/<skill-name> -> ../../.agents/skills/<skill-name>`
  - Codex CLI: `~/.codex/skills/<skill-name> -> ../../.agents/skills/<skill-name>`
  - Other agents: ask the user for their skill directory convention.
- Default target agent is the one currently running this skill, unless the user names a different one.

Treat `~/.agents/skills` + symlink as the default path end-to-end. If the user asks for a different dest root, a copy instead of a symlink, or a nonstandard agent directory, confirm with them before writing anything outside the default layout.

## Workflow

1. **Locate Xcode.** Default app path is `/Applications/Xcode.app`. If that path doesn't exist, run `mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"` to find installed copies, or ask the user. Xcode does not need to be running — the resources are read straight off disk.
2. **Discover extractable skills.** Run:
   ```bash
   scripts/extract-xcode-skill.sh --list [xcode.app path]
   ```
   This lists real, user-facing skill names (internal harness prompts like `BasicSystemPrompt` or `ToolAssisted` are already filtered out).
3. **Decide scope.**
   - Default: extract every skill from the list.
   - If the user named specific skill(s), extract only those (validate the names against the `--list` output first; if a name doesn't match, say so instead of guessing).
   - Either way, it's fine to show the discovered list and confirm before a bulk extraction — use judgment based on list size and how explicit the user's request was.
4. **Extract each skill into the canonical store:**
   ```bash
   scripts/extract-xcode-skill.sh <skill-name> [xcode.app path]
   ```
   Omit the third (`dest root`) argument to keep the default `~/.agents/skills`. Only pass an explicit dest root if the user asked for one — and confirm with them first, per Install Layout above.
5. **Make it visible to the target agent(s).** For each extracted skill, check the agent's skill directory (e.g. `~/.claude/skills/<skill-name>`):
   - Missing: create it — `ln -s ../../.agents/skills/<skill-name> <agent-skills-dir>/<skill-name>`.
   - Already a symlink pointing at the same canonical path: nothing to do, report it as already installed.
   - Anything else (a real directory/file, or a symlink pointing elsewhere): stop and ask the user before replacing it.
6. **Report results:** which skills were extracted, how many reference files each had, the canonical path, and which agent symlinks were created vs. already present vs. skipped pending confirmation.

## Boundaries

- Never delete or overwrite an existing non-symlink skill directory without explicit user confirmation.
- Never invent skill names — only act on names returned by `--list` (or explicitly given by the user and verified against that list).
- Don't decode or transform the `.idechatprompttemplate` / `*-ref-*.md.packaged` files beyond copying and renaming; they are already plain markdown.
- Don't run this against Xcode versions before 27 — `IDEIntelligenceChat.framework` and this resource layout are specific to Xcode 27+.
