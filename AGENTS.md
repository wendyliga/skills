# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure & Module Organization

This repository packages reusable AI-tool skills. Root files hold repository-level documentation and install instructions. Skill packages live under `skills/<skill-name>/`; the current package is `skills/xcode/`.

Each skill should include a `SKILL.md` entry point with YAML front matter, clear invocation guidance, workflows, boundaries, and references. Put supporting long-form material in `skills/<skill-name>/references/`. Agent integration metadata belongs in `skills/<skill-name>/agents/`, such as `agents/openai.yaml`.

## Build, Test, and Development Commands

No local build step is required; this is a documentation-driven skill repository.

- `npx -y skills add wendyliga/skills --list`: list available skills from this repository.
- `npx -y skills add wendyliga/skills --all`: install every skill.
- `npx -y skills add wendyliga/skills --skill xcode`: install only the Xcode skill.
- `npx -y skills remove xcode`: remove the installed Xcode skill.

Run commands from the repository root unless a tool states otherwise.

## Coding Style & Naming Conventions

Use Markdown for skill docs and YAML for agent metadata. Keep headings descriptive and task-oriented. Prefer short paragraphs, concrete tool names, and command examples over abstract guidance.

Use two-space indentation in YAML. Name skill directories with lowercase kebab-case, for example `skills/xcode` or `skills/my-skill`. Keep front matter fields minimal and stable: `name` and `description` are required for skill discovery.

## Testing Guidelines

There is no automated test suite in this repository. Validate changes by checking Markdown readability, YAML syntax, and install visibility.

For changed skills, run `npx -y skills add wendyliga/skills --list` when network access is available, then install the touched skill with `--skill <name>` to confirm packaging works. The `/validate-skill` project skill automates this.

## Commit & Pull Request Guidelines

Git history currently uses concise, imperative commit messages, for example `Add initial .gitignore, README, and Xcode skill documentation`. Follow that style: state what changed and name the affected skill when useful.

Pull requests should include a short purpose statement, changed skill paths, validation performed, and any screenshots only when UI or rendered documentation output is relevant.

## Agent-Specific Instructions

Do not edit installed copies of skills outside this repository. Update source files under `skills/`, then reinstall through the skills CLI when verification requires it.

## Additional notes

- MCP servers can report as "connected" (`claude mcp list`) while exposing zero tools — this usually means the underlying app (e.g. Xcode) isn't open, not that the server needs reinstalling. Don't jump to re-registering a server without checking that first.
