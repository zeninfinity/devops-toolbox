#!/bin/bash
# Removes the roots behind the compromised eMudhra intermediate CAs from /etc/ssl/cert.pem
# (Apple notice, 2026-10-23). Used by curl, git, and macOS python3/ruby/perl/openssl.
#
#   emudhra-cert-pem.sh status     show which of the two roots are present (no sudo)
#   emudhra-cert-pem.sh apply      back up, remove both roots, verify
#   emudhra-cert-pem.sh rollback   restore the original file from the backup
#   emudhra-cert-pem.sh rollback --drop-backup   same, then delete the backup
#
# Backup: /etc/ssl/cert.pem.orig (never overwritten once it exists).
# Re-run "status" after each macOS update until Apple ships its fix. If the roots are
# back, the update replaced the file: run "sudo rm /etc/ssl/cert.pem.orig", then "apply"
# (the old backup is from before the update and must not be restored over it).
set -euo pipefail

PEM=${PEM:-/etc/ssl/cert.pem}
BAK=${BAK:-$PEM.orig}
# TEST=1 runs against a copy without sudo (for testing only).
if [ -n "${TEST:-}" ]; then sudo() { [ "$1" = install ] && { shift; cp "${@: -2:1}" "${@: -1}"; } || "$@"; }; fi
ROOTS=(
  '=== /C=IN/OU=emSign PKI/O=eMudhra Technologies Limited/CN=emSign ECC Root CA - G3'
  '=== /C=GB/ST=Greater Manchester/L=Salford/O=Comodo CA Limited/CN=AAA Certificate Services'
)
PATTERN='emSign ECC Root CA - G3|AAA Certificate Services'

count_certs() { grep -c 'BEGIN CERTIFICATE' "$1"; }

present() {
  openssl crl2pkcs7 -nocrl -certfile "$1" | openssl pkcs7 -print_certs -noout \
    | grep '^subject=' | grep -E "$PATTERN" || true
}

status() {
  local p; p=$(present "$PEM")
  echo "$PEM: $(count_certs "$PEM") certificates"
  if [ -n "$p" ]; then echo "Still present:"; echo "$p"; else echo "Both roots removed."; fi
  if [ -e "$BAK" ]; then echo "Backup: $BAK ($(count_certs "$BAK") certificates)"; else echo "Backup: none"; fi
}

apply() {
  if [ -z "$(present "$PEM")" ]; then echo "Nothing to do, both roots already removed."; status; exit 0; fi

  if [ -e "$BAK" ]; then
    echo "Backup already exists, keeping it: $BAK"
  else
    sudo cp -p "$PEM" "$BAK"
    echo "Backed up to $BAK"
  fi

  t=$(mktemp)
  trap 'rm -f "$t" "$t.new"' EXIT
  cp "$PEM" "$t"
  for s in "${ROOTS[@]}"; do
    awk -v s="$s" '/^(===|###) /{skip=0} $0==s{skip=1} !skip' "$t" > "$t.new" && mv "$t.new" "$t"
  done

  # Safety checks before touching the real file.
  local before after; before=$(count_certs "$PEM"); after=$(count_certs "$t")
  removed=$((before - after))
  if [ ! -s "$t" ] || [ -n "$(present "$t")" ] || [ "$removed" -lt 1 ] || [ "$removed" -gt 2 ]; then
    echo "Safety check failed (before $before, after $after). $PEM not changed." >&2
    exit 1
  fi
  openssl crl2pkcs7 -nocrl -certfile "$t" >/dev/null || { echo "New file does not parse. $PEM not changed." >&2; exit 1; }

  sudo install -m 0644 -o root -g wheel "$t" "$PEM"
  echo "Removed $removed root(s): $before -> $after certificates."
  curl -sS -o /dev/null -w "curl https://github.com: %{http_code}\n" https://github.com \
    || echo "curl test failed. Roll back with: $0 rollback" >&2
  status
}

rollback() {
  [ -e "$BAK" ] || { echo "No backup at $BAK, nothing to roll back." >&2; exit 1; }
  sudo install -m 0644 -o root -g wheel "$BAK" "$PEM"
  echo "Restored $PEM from $BAK."
  if [ "${1:-}" = "--drop-backup" ]; then sudo rm -f "$BAK"; echo "Deleted $BAK."; fi
  status
}

case "${1:-}" in
  status) status ;;
  apply) apply ;;
  rollback) rollback "${2:-}" ;;
  *) echo "usage: $0 status | apply | rollback [--drop-backup]" >&2; exit 2 ;;
esac
