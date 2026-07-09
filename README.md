# Skills

Reusable skills for skill-compatible AI coding tools.

## Installation

### Full Install

Install every skill in this repository:

```bash
npx skills add wendyliga/skills
```

Restart your AI coding tool after installation so new skills are loaded.

### Single Skill Install

| Skill | Explanation | Install command |
| --- | --- | --- |
| `xcode` | Guide for using Xcode MCP tools to inspect and drive Xcode workspaces, schemes, destinations, builds, tests, SwiftUI previews, runtime logs, debugger commands, device interaction, project configuration, Apple documentation, crash reports, and performance diagnostics. | `npx skills add wendyliga/skills --skill xcode` |
| `extract-xcode-skills` | Extracts Xcode 27's built-in agentic chat skills (e.g. `swiftui-specialist`, `uikit-app-modernization`) out of Xcode.app and installs them as SKILL.md packages for external agents. | `npx skills add wendyliga/skills --skill extract-xcode-skills` |

## List Skills

See skills available in this repository:

```bash
npx -y skills add wendyliga/skills --list
```

## Delete Skills

Remove a specific skill:

```bash
npx -y skills remove xcode
```

Remove all installed skills from this repository:

```bash
npx -y skills remove --all
```
