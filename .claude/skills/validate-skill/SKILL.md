---
name: validate-skill
description: Validate a skill in this repo (skills/<name>/) before committing — checks SKILL.md frontmatter and does a real install test via the skills CLI. Use when the user says "validate this skill", "check the xcode skill works", "test my new skill", or after editing any skills/*/SKILL.md file.
---

Validate `skills/<name>/` per this repo's AGENTS.md testing guidelines. `<name>` comes from the user's request, or infer it from whichever `skills/*/SKILL.md` was just edited.

## 1. Frontmatter check

Read `skills/<name>/SKILL.md` and confirm:
- YAML frontmatter parses (opening/closing `---` present, valid YAML).
- `name` field is present and matches the directory name exactly.
- `description` field is present and non-empty.

If any of these fail, stop and report the specific problem — don't proceed to install testing on a file that won't parse.

## 2. Real install test

Run the actual installer against a scratch location so the test never touches this repo's own `.claude/skills/`:

```bash
tmpdir=$(mktemp -d)
cp -r . "$tmpdir/repo"
cd "$tmpdir/repo" && npx -y skills add . --skill <name> --agent claude-code -y
```

Confirm the command reports the skill installed successfully and diff the installed `SKILL.md` against the source to confirm it copied through unmodified:

```bash
diff skills/<name>/SKILL.md "$tmpdir/repo/.claude/skills/<name>/SKILL.md"
```

Clean up afterward:

```bash
rm -rf "$tmpdir"
```

## 3. Report

Tell the user pass/fail for each check. If everything passes, the skill is safe to commit and publish via `npx -y skills add wendyliga/skills --skill <name>`.
