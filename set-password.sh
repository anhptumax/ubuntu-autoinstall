#!/usr/bin/env bash
#
# Dat san tai khoan + mat khau cho autoinstall, de trinh cai khong hoi nua.
#
#   ./set-password.sh            # nhap tai khoan/mat khau
#   ./set-password.sh --reset    # quay ve che do nhap tay trong trinh cai
#
# Mat khau duoc bam thanh chuoi hash SHA-512 (crypt) truoc khi ghi vao file.
# Ban than mat khau khong bao gio duoc ghi ra dia.
#
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$0")")"

readonly TEMPLATE="autoinstall/user-data.tmpl"
readonly BEGIN="  # >>> IDENTITY >>>"
readonly END="  # <<< IDENTITY <<<"

grep -qF "${BEGIN}" "${TEMPLATE}" || { echo "Khong tim thay moc IDENTITY trong ${TEMPLATE}." >&2; exit 1; }

# Doc khoi YAML tu stdin, thay vao giua 2 moc IDENTITY.
replace_block() {
  local body
  body="$(cat)"
  IDENTITY_BLOCK="${body}" python3 -c '
import os, sys
path, begin, end = sys.argv[1:4]
body = os.environ["IDENTITY_BLOCK"].rstrip("\n")
text = open(path).read()
i = text.index(begin)
j = text.index(end) + len(end)
open(path, "w").write(text[:i] + begin + "\n" + body + "\n" + end + text[j:])
' "${TEMPLATE}" "${BEGIN}" "${END}"
}

if [[ "${1:-}" == "--reset" ]]; then
  replace_block <<'BLOCK'
  interactive-sections:
    - storage
    - identity
BLOCK
  ./build.sh
  echo
  echo "Da quay ve che do nhap tay. Trinh cai se hoi tai khoan/mat khau nhu binh thuong."
  exit 0
fi

read -rp "Ten dang nhap        [umaxsoft] : " USERNAME
USERNAME="${USERNAME:-umaxsoft}"
read -rp "Ten hien thi         [${USERNAME}] : " REALNAME
REALNAME="${REALNAME:-${USERNAME}}"
read -rp "Ten may (hostname)   [ubuntu-pc] : " HOSTNAME_
HOSTNAME_="${HOSTNAME_:-ubuntu-pc}"

if [[ ! "${USERNAME}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Ten dang nhap khong hop le (chi chu thuong, so, '-', '_')." >&2
  exit 1
fi

read -rsp "Mat khau                         : " PASS1; echo
read -rsp "Nhap lai mat khau                : " PASS2; echo
[[ -n "${PASS1}" ]]            || { echo "Mat khau rong." >&2; exit 1; }
[[ "${PASS1}" == "${PASS2}" ]] || { echo "Hai lan nhap khong khop." >&2; exit 1; }

HASH="$(printf '%s' "${PASS1}" | openssl passwd -6 -stdin)"
unset PASS1 PASS2
[[ "${HASH}" == \$6\$* ]] || { echo "Sinh hash that bai." >&2; exit 1; }

replace_block <<BLOCK
  interactive-sections:
    - storage

  identity:
    hostname: ${HOSTNAME_}
    realname: ${REALNAME}
    username: ${USERNAME}
    password: "${HASH}"
BLOCK

./build.sh

cat <<INFO

======================================================================
  Da dat san tai khoan '${USERNAME}' tren may '${HOSTNAME_}'.
  Trinh cai chi con hoi phan chon o dia.

  CANH BAO: file autoinstall gio chua HASH mat khau.
  Hash nay be khoa duoc bang tu dien neu mat khau de doan.
    - Repo PUBLIC  -> coi nhu mat khau da lo, doi mat khau sau khi cai.
    - An toan hon  -> de repo private va dung ./serve.sh trong mang LAN.

  Quay ve che do nhap tay:  ./set-password.sh --reset
======================================================================

INFO
