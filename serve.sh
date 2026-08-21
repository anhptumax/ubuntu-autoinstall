#!/usr/bin/env bash
#
# Host file autoinstall qua HTTP trong mang LAN, de dien vao o "Automated installation"
# cua trinh cai Ubuntu Desktop.
#
#   ./serve.sh [port]        # mac dinh port 3003
#
# Chay tren MOT MAY KHAC (may dang dung), khong phai may sap cai.
# Ctrl+C de dung.
#
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$0")")"

PORT="${1:-3003}"

./build.sh

SERVE_DIR="$(mktemp -d)"
trap 'rm -rf "${SERVE_DIR}"' EXIT

# Cung mot noi dung, 2 ten file cho 2 cach nap:
#   autoinstall.yaml -> dien vao o URL cua trinh cai Desktop
#   user-data + meta-data -> dung voi tham so kernel ds=nocloud-net
cp autoinstall/user-data "${SERVE_DIR}/autoinstall.yaml"
cp autoinstall/user-data "${SERVE_DIR}/user-data"
cp autoinstall/meta-data "${SERVE_DIR}/meta-data"

IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1)"
[[ -n "${IP}" ]] || IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
[[ -n "${IP}" ]] || { echo "Khong xac dinh duoc IP LAN." >&2; exit 1; }

cat <<INFO

======================================================================
  Dang phuc vu file autoinstall tai http://${IP}:${PORT}/

  CACH 1 — Trinh cai Ubuntu Desktop (o "Automated installation"):

      http://${IP}:${PORT}/autoinstall.yaml

      Luu y: phai bam "Connect to network" TRUOC, roi moi chon
      "Automated installation" va dan link tren vao.

  CACH 2 — Tham so kernel o man hinh GRUB (bam 'e', them vao dong linux):

      autoinstall ds=nocloud-net;s=http://${IP}:${PORT}/

  May sap cai phai cung mang LAN va truy cap duoc IP nay.
  Neu tuong lua dang bat, mo cong:  sudo ufw allow ${PORT}/tcp

  Ctrl+C de dung.
======================================================================

INFO

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi '^Status: active'; then
  ufw status 2>/dev/null | grep -q "${PORT}" \
    || echo "CANH BAO: ufw dang bat va cong ${PORT} co ve chua duoc mo." >&2
fi

exec python3 -m http.server "${PORT}" --bind 0.0.0.0 --directory "${SERVE_DIR}"
