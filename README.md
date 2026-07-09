# Skills

Reusable skills for skill-compatible AI coding tools.

## Installation

### Full Install

Install every skill in this repository:

```bash
npx -y skills add wendyliga/skills --all
```

Restart your AI coding tool after installation so new skills are loaded.

### Single Skill Install

| Skill | Explanation | Install command |
| --- | --- | --- |
| `xcode` | Guide for using Xcode MCP tools to inspect and drive Xcode workspaces, schemes, destinations, builds, tests, SwiftUI previews, runtime logs, debugger commands, device interaction, project configuration, Apple documentation, crash reports, and performance diagnostics. | `npx -y skills add wendyliga/skills --skill xcode` |

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
