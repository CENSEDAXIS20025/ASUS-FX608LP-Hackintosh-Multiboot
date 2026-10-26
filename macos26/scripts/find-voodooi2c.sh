#!/bin/bash
# 在 macOS 里找包含 VoodooI2CPCILakeController 的补丁版 VoodooI2C
sudo find /Library/Extensions /System/Library/Extensions /Users /Volumes -name 'VoodooI2C.kext' 2>/dev/null | while read -r k; do
  echo "=== $k"
  if strings "$k/Contents/MacOS/VoodooI2C" 2>/dev/null | grep -qi 'LakeController'; then
    echo ">>> PATCHED FOUND: $k"
  else
    echo "(no LakeController)"
  fi
done
