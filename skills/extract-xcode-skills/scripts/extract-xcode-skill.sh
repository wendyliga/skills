#!/usr/bin/env bash
# Extract an Xcode 27 built-in chat skill into a SKILL.md skill dir.
#
# Source of truth: Xcode.app's IDEIntelligenceChat.framework Resources bundle.
# Both `.idechatprompttemplate` (the SKILL.md body) and `<skill>-ref-*.md.packaged`
# (the references/*.md files) are plain UTF-8 markdown despite the extensions —
# no decoding needed, just renaming.
#
# Usage:
#   extract-xcode-skill.sh --list [xcode.app path]
#   extract-xcode-skill.sh <skill-name> [xcode.app path] [dest root]
#
# Default dest root is ~/.agents/skills, the canonical multi-agent skill
# store. Symlink extracted skills from there into a specific agent's skill
# directory (e.g. ~/.claude/skills/<skill>) as a separate step.
set -euo pipefail

XCODE_APP_DEFAULT="/Applications/Xcode-27.0.app"
DEST_ROOT_DEFAULT="$HOME/.agents/skills"

EXCLUDE_PATTERN='^(AdditionalFiles|AgentAdditionalContext|AgentSystemPromptAddition|BasicSystemPrompt|ChatTitleResolver|CodingToolTemplate|ContextItems|CurrentFile|CurrentSelection|FastApplyIntegrator|GenerateDocumentation|GeneratePlayground|GeneratePreview|InQuery|InstructionEmbeddings|Integrator|Interfaces|Issues|LocalInfillEmbeddings|NewCodeIntegrator|NewKnowledge|NoSelection|OriginalFile|PlannerExecutor|PromptSuggestionGenerator|Query\.|ReasoningSystemPrompt|SearchResults|Snippets|TextEditorToolSystemPrompt|ToolAssisted|VariantA|VariantB)'

list_skills() {
  local res="$1"
  ls "$res" \
    | grep '\.idechatprompttemplate$' \
    | grep -v -E "$EXCLUDE_PATTERN" \
    | sed 's/\.idechatprompttemplate$//'
}

if [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
  XCODE_APP="${2:-$XCODE_APP_DEFAULT}"
  RES="$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources"
  list_skills "$RES"
  exit 0
fi

SKILL="${1:?usage: extract-xcode-skill.sh <skill-name>|--list [xcode.app path] [dest dir]}"
XCODE_APP="${2:-$XCODE_APP_DEFAULT}"
DEST_ROOT="${3:-$DEST_ROOT_DEFAULT}"

RES="$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources"
TEMPLATE="$RES/$SKILL.idechatprompttemplate"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "error: no template found at $TEMPLATE" >&2
  echo >&2
  echo "available skills in this Xcode:" >&2
  list_skills "$RES" >&2
  exit 1
fi

DEST="$DEST_ROOT/$SKILL"
mkdir -p "$DEST/references"

cp "$TEMPLATE" "$DEST/SKILL.md"

shopt -s nullglob
count=0
for f in "$RES/$SKILL-ref-"*.md.packaged; do
  base="$(basename "$f")"
  short="${base#"$SKILL"-ref-}"
  short="${short%.packaged}"
  cp "$f" "$DEST/references/$short"
  count=$((count + 1))
done

echo "Extracted '$SKILL' -> $DEST ($count reference file(s))"
