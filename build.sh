#!/usr/bin/env bash
#
# Sinh autoinstall/user-data tu autoinstall/user-data.tmpl + scripts/post-install.sh.
# Chay lai moi khi sua 1 trong 2 file nguon do.
#
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$0")")"

TEMPLATE="autoinstall/user-data.tmpl"
SCRIPT="scripts/post-install.sh"
OUTPUT="autoinstall/user-data"

for f in "${TEMPLATE}" "${SCRIPT}"; do
  [[ -f "$f" ]] || { echo "Thieu file: $f" >&2; exit 1; }
done

bash -n "${SCRIPT}" || { echo "post-install.sh co loi cu phap." >&2; exit 1; }

python3 - "${TEMPLATE}" "${SCRIPT}" "${OUTPUT}" <<'PY'
import sys

template_path, script_path, output_path = sys.argv[1:4]
PLACEHOLDER = "@@POST_INSTALL_SCRIPT@@"
INDENT = " " * 6          # do sau thut le cua noi dung heredoc trong YAML
TERMINATOR = "POST_INSTALL_SCRIPT_EOF"

script = script_path and open(script_path).read()
if TERMINATOR in script:
    sys.exit(f"LOI: {script_path} chua chuoi '{TERMINATOR}' -> se lam hong heredoc.")

body = "\n".join(INDENT + line if line.strip() else line
                 for line in script.splitlines())

template = open(template_path).read()
if PLACEHOLDER not in template:
    sys.exit(f"LOI: khong thay {PLACEHOLDER} trong {template_path}.")

open(output_path, "w").write(template.replace(PLACEHOLDER, body))

# --- kiem tra lai ket qua ---
try:
    import yaml
except ImportError:
    print("  (bo qua kiem tra YAML: chua co python3-yaml)")
    sys.exit(0)

data = yaml.safe_load(open(output_path))
ai = data["autoinstall"]
late = ai["late-commands"][0]
assert "#!/usr/bin/env bash" in late, "script khong duoc nhung vao late-commands"
assert late.count("\n" + TERMINATOR) == 1, "heredoc khong dong dung mot lan"
assert "install_rustdesk" in late, "noi dung script bi cat"
print("  YAML hop le, script da duoc nhung nguyen ven.")
PY

echo "Da sinh: ${OUTPUT} ($(wc -l < "${OUTPUT}") dong)"
