#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)
file=$(echo "$payload" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

case "$file" in
  */skills/*/SKILL.md) ;;
  *) exit 0 ;;
esac

dir_name=$(basename "$(dirname "$file")")

python3 - "$file" "$dir_name" <<'PYEOF'
import re, sys, json

path, dir_name = sys.argv[1], sys.argv[2]
text = open(path).read()

m = re.match(r'^---\n(.*?\n)---\n', text, re.DOTALL)
if not m:
    print(json.dumps({"decision": "block", "reason": f"{path}: missing or malformed YAML frontmatter (must start with '---' and close with '---')."}))
    sys.exit(0)

fm = m.group(1)
name_m = re.search(r'^name:\s*["\']?([\w-]+)["\']?\s*$', fm, re.MULTILINE)
desc_m = re.search(r'^description:', fm, re.MULTILINE)

errors = []
if not name_m:
    errors.append("missing 'name' field")
elif name_m.group(1) != dir_name:
    errors.append(f"'name: {name_m.group(1)}' does not match directory 'skills/{dir_name}/'")
if not desc_m:
    errors.append("missing 'description' field")

if errors:
    print(json.dumps({"decision": "block", "reason": f"{path}: " + "; ".join(errors)}))
PYEOF
