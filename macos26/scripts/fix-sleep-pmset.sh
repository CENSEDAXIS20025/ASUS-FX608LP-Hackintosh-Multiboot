#!/bin/bash
# 在 macOS 里运行：bash "/Volumes/软件和文件盘/移动设备共享盘/fix-sleep-pmset.sh"
echo "=== before ==="
pmset -g | egrep 'hibernatemode|standby|autopoweroff|powernap|womp|proximitywake|acwake' || true
for kv in "hibernatemode 0" "standby 0" "autopoweroff 0" "powernap 0" "womp 0" "proximitywake 0" "acwake 0"; do
  sudo pmset -a $kv 2>&1 || true
done
echo "=== after ==="
pmset -g | egrep 'hibernatemode|standby|autopoweroff|powernap|womp|proximitywake|acwake' || true
echo "完成。重启后测试睡眠。"
