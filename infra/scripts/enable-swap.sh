#!/usr/bin/env bash
set -euo pipefail

swapfile="${1:-/swapfile}"
size_mb="${2:-2048}"

if ! swapon --show=NAME --noheadings | grep -qx "$swapfile"; then
  if [ ! -f "$swapfile" ]; then
    fallocate -l "${size_mb}M" "$swapfile" || dd if=/dev/zero of="$swapfile" bs=1M count="$size_mb"
  fi

  chmod 600 "$swapfile"
  mkswap -f "$swapfile"
  swapon "$swapfile"
fi

if ! grep -q "^${swapfile} " /etc/fstab; then
  printf '%s none swap sw 0 0\n' "$swapfile" >> /etc/fstab
fi

free -m
