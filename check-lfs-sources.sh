#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://www.linuxfromscratch.org/lfs/downloads/systemd"
LFS="${LFS:-/mnt/lfs}"
SRCDIR="$LFS/sources"

cd "$SRCDIR"

fetch() {
  local url="$1" out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSLo "$out" "$url"
  else
    wget -qO "$out" "$url"
  fi
}

download_list() {
  local listfile="$1"
  if command -v wget >/dev/null 2>&1; then
    wget --input-file="$listfile" --continue --directory-prefix="$SRCDIR"
  else
    # curl fallback: download each URL one by one
    while IFS= read -r url; do
      [[ -z "$url" ]] && continue
      [[ "$url" =~ ^# ]] && continue
      file="${url##*/}"
      curl -fL --retry 3 --retry-delay 2 -o "$SRCDIR/$file" "$url"
    done < "$listfile"
  fi
}

echo "==> Using sources dir: $SRCDIR"

# 1) Ensure official lists exist (refresh them each run)
echo "==> Fetching official wget-list and md5sums..."
fetch "$BASE_URL/wget-list" "wget-list"
fetch "$BASE_URL/md5sums"  "md5sums"

# 2) Check presence
echo "==> Checking presence..."
missing=0
: > missing-urls.txt

while IFS= read -r url; do
  [[ -z "$url" ]] && continue
  [[ "$url" =~ ^# ]] && continue
  file="${url##*/}"
  if [[ ! -e "$file" ]]; then
    echo "MISSING: $file"
    echo "$url" >> missing-urls.txt
    missing=$((missing+1))
  fi
done < wget-list

if [[ "$missing" -gt 0 ]]; then
  echo "==> Downloading $missing missing file(s)..."
  download_list "missing-urls.txt"
else
  echo "OK: all files from wget-list are present."
fi

# 3) Verify MD5
echo "==> Verifying MD5 (md5sum -c md5sums)"
md5sum -c md5sums
echo "OK: all MD5 sums match."
