#!/usr/bin/env bash
# Extract an Xcode 27 built-in agentic skill into a standalone SKILL.md skill dir.
#
# Xcode 27 ships skill content through two different mechanisms, and a given
# skill lives in exactly one of them:
#
#   A. IDEIntelligenceChat.framework/.../Resources/<skill>.idechatprompttemplate
#      + <skill>-ref-*.md.packaged (flat, skill-name-prefixed files).
#      e.g. swiftui-specialist, swiftui-whats-new-27, uikit-app-modernization,
#      audit-xcode-security-settings, adopt-c-bounds-safety.
#
#   B. Not statically bundled in Xcode.app at all. Xcode's IDEIntelligenceAgents
#      daemon stages these at runtime into a per-build temp dir
#      (/private/var/.../T/com.apple.dt.IDEIntelligenceAgents/plugins/<build>/xcode-integration/skills/)
#      and mirrors them into a persistent local cache once used:
#        ~/Library/Developer/Xcode/CodingAssistant/codex/skills/__xcode/<skill>/
#      Already plain SKILL.md + references/*.md, no renaming needed — just copy.
#      e.g. accessibility-dynamic-type-specialist, accessibility-voiceover-specialist,
#      device-interaction, modernize-tests.
#      This is a *fallback*, not a bundled source: it only exists locally after
#      Xcode's assistant has been used at least once, and the temp path can be
#      purged by the OS — the ~/Library cache copy is the more durable of the two,
#      so that's what this script reads.
#
# Both are plain UTF-8 markdown despite the `.packaged`/`.idechatprompttemplate`
# extensions — no decoding required, just discovery + copy + rename.
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
CACHE_FALLBACK_DEFAULT="$HOME/Library/Developer/Xcode/CodingAssistant/codex/skills/__xcode"

EXCLUDE_PATTERN='^(AdditionalFiles|AgentAdditionalContext|AgentSystemPromptAddition|BasicSystemPrompt|ChatTitleResolver|CodingToolTemplate|ContextItems|CurrentFile|CurrentSelection|FastApplyIntegrator|GenerateDocumentation|GeneratePlayground|GeneratePreview|InQuery|InstructionEmbeddings|Integrator|Interfaces|Issues|LocalInfillEmbeddings|NewCodeIntegrator|NewKnowledge|NoSelection|OriginalFile|PlannerExecutor|PromptSuggestionGenerator|Query\.|ReasoningSystemPrompt|SearchResults|Snippets|TextEditorToolSystemPrompt|ToolAssisted|VariantA|VariantB)'

chat_res_dir() { echo "$1/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources"; }

list_chat_skills() {
  local res; res="$(chat_res_dir "$1")"
  [[ -d "$res" ]] || return 0
  ls "$res" \
    | grep '\.idechatprompttemplate$' \
    | grep -v -E "$EXCLUDE_PATTERN" \
    | sed 's/\.idechatprompttemplate$//'
}

list_cache_skills() {
  [[ -d "$CACHE_FALLBACK" ]] || return 0
  find "$CACHE_FALLBACK" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;
}

if [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
  XCODE_APP="${2:-$XCODE_APP_DEFAULT}"
  CACHE_FALLBACK="${CACHE_FALLBACK:-$CACHE_FALLBACK_DEFAULT}"
  { list_chat_skills "$XCODE_APP"; list_cache_skills; } | sort -u
  exit 0
fi

SKILL="${1:?usage: extract-xcode-skill.sh <skill-name>|--list [xcode.app path] [dest dir]}"
XCODE_APP="${2:-$XCODE_APP_DEFAULT}"
DEST_ROOT="${3:-$DEST_ROOT_DEFAULT}"
CACHE_FALLBACK="${CACHE_FALLBACK:-$CACHE_FALLBACK_DEFAULT}"

DEST="$DEST_ROOT/$SKILL"

extract_from_chat_framework() {
  local template="$1"
  local res; res="$(chat_res_dir "$XCODE_APP")"
  mkdir -p "$DEST/references"
  cp "$template" "$DEST/SKILL.md"

  shopt -s nullglob
  local count=0
  for f in "$res/$SKILL-ref-"*.md.packaged; do
    local base short
    base="$(basename "$f")"
    short="${base#"$SKILL"-ref-}"
    short="${short%.packaged}"
    cp "$f" "$DEST/references/$short"
    count=$((count + 1))
  done
  rmdir --ignore-fail-on-non-empty "$DEST/references" 2>/dev/null || true
  echo "Extracted '$SKILL' -> $DEST ($count reference file(s)) [source: IDEIntelligenceChat.framework]"
}

extract_from_cache() {
  local cache_dir="$1"
  mkdir -p "$DEST_ROOT"
  rm -rf "$DEST"
  cp -R "$cache_dir" "$DEST"
  local count=0
  [[ -d "$DEST/references" ]] && count=$(find "$DEST/references" -type f | wc -l | tr -d ' ')
  echo "Extracted '$SKILL' -> $DEST ($count reference file(s)) [source: local Xcode assistant cache, not statically bundled in Xcode.app]"
}

CHAT_TEMPLATE="$(chat_res_dir "$XCODE_APP")/$SKILL.idechatprompttemplate"
CACHE_DIR="$CACHE_FALLBACK/$SKILL"

if [[ -f "$CHAT_TEMPLATE" ]]; then
  extract_from_chat_framework "$CHAT_TEMPLATE"
elif [[ -d "$CACHE_DIR" && -f "$CACHE_DIR/SKILL.md" ]]; then
  extract_from_cache "$CACHE_DIR"
else
  echo "error: '$SKILL' not found in Xcode.app (IDEIntelligenceChat resources) or in the local assistant cache ($CACHE_FALLBACK)" >&2
  echo >&2
  echo "available skills:" >&2
  { list_chat_skills "$XCODE_APP"; list_cache_skills; } | sort -u >&2
  exit 1
fi
