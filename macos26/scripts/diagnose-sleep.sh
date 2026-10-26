#!/bin/bash
# 睡死/唤醒失败后，在 macOS 里运行：
# bash "/Volumes/软件和文件盘/移动设备共享盘/diagnose-sleep.sh" > ~/Desktop/sleep-log.txt
echo "=== pmset -g ==="; pmset -g
echo "=== pmset -g assertions ==="; pmset -g assertions
echo "=== pmset -g log (tail 120) ==="; pmset -g log | tail -120
echo "=== unified log ==="; log show --last 15m --predicate 'eventMessage CONTAINS[c] "wake" OR eventMessage CONTAINS[c] "sleep"' | tail -120
