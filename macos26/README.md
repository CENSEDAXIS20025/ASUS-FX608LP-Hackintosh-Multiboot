> **归档说明**：这里是原始导出的**精简版**。原始导出共 257 文件 / 272.87 MB，
> 其中 `EFI/`（80 MB 快照）、`artifacts/packages/`（26 MB 安装包）、`previous/`（106 MB 旧归档）
> **没有重复上传**。
> 本目录收录：**报告 + 取证材料 + 脚本 + 当前 config + 会话日志**。
> 完整 EFI 见仓库根目录的 `EFI/`（那是 **macOS 15** 版；macOS 26 版未上传）。

---

# ZCode 黑苹果会话导出（独立文件夹版）

- 导出时间：2026-10-27 01:35（Asia/Shanghai）
- 说明：本次导出全部放在本文件夹内，不再在共享盘根目录散放文件；旧归档和旧脚本已移入 `previous/` 和 `scripts/`。
- 这是 **01:35 的快照**：WiFi/音频/触控板/OC RELEASE/睡眠修复的重启验证尚未发生。
- 机器：Intel Arrow Lake 笔记本，UEFI + OpenCore，macOS 26 Tahoe / Ubuntu / Windows
- 当前 OpenCore：**1.0.9 RELEASE**（Dortania build-repo，构建 `OpenCorePkg-78d5ff8`）
- 当前 ESP：`nvme1n1p4` / PARTUUID `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`（Linux 设备名可能交换）
- 固件启动项：`0007 OpenCore` -> `\EFI\BOOT\BOOTx64.efi`；`0001 Ubuntu` -> `\EFI\ubuntu\shimx64.efi`；`0000 Windows Boot Manager`
- SMBIOS：`MacBookPro16,1`；`SecureBootModel=Disabled`；`DisableIoMapper=true`；`csr-active-config=0x0A43`
- **FileVault 已开启**：APFS `MacOS - 数据` 卷在 Linux 下是锁定状态。

## 1. 本次会话完成/尝试的事项

### 1.1 开机进 grub、OC 菜单与 Ubuntu 项
- 固件启动项原本已指向 OC，但 OC 自定义 Ubuntu 项使用相对路径，日志报 `OCB: LoadImage failed - Not Found`。
- 修复为完整 UEFI 设备路径：
  `PciRoot(0x1)/Pci(0x1D,0x0)/Pci(0x0,0x0)/NVMe(0x1,XX-XX-XX-XX-XX-XX-XX-XX)/HD(4,GPT,XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX,0xDB8AD800,0x219800)/\EFI\ubuntu\shimx64.efi`
- 关键点：`PciRoot` 是 `0x1`；NVMe EUI64 在 UEFI 中为 `XX-XX-XX-XX-XX-XX-XX-XX`（Linux sysfs 的 `XX-XX-XX-XX-XX-XX-XX-XX` 为反序）。

### 1.2 macOS 26 USB 全部失效
- Tahoe 将 USB 端口属性名从 `UsbConnector`/`port` 改为 `usb-port-type`/`usb-port-number`。
- 在 `USBMap.kext` 的 12 个端口中同时保留旧键并新增新键，并加 `kUSBMuxEnabled=true`。
- 结果：USB 已恢复（用户确认）。

### 1.3 WiFi（Intel AX210）
- 原 `AirportItlwm 2.4.0` 是 Sequoia 构建（`sequoia-vtd-1`），Tahoe 无法加载。
- 替换为 `AirportItlwm-Tahoe-v2.4.0-RELEASE-alpha`（`tahoe-vtd-1`），并加 `itlwm_he=1`。
- 状态：已安装，**待重启验证**。

### 1.4 音频（Realtek ALC256）
- macOS 26 移除 `AppleHDA.kext`，AppleALC 没有后端。
- 安装 `SimpleHDA-Tahoe-v1.0.0-RELEASE`（SHA256 校验通过），`Kernel > Add` 排在 AppleALC 后，`MinKernel=25.0.0` / `MaxKernel=25.99.99`；加 `keepsyms=1`。
- 状态：已安装，**待重启验证**；`SimpleHDA-HAL-1.0.0.pkg` 未装。

### 1.5 触控板（ELAN 04F3:32E2，I2C-HID）
- 硬件：ELAN 04F3:32E2，ACPI `ASCE1200`，`compatible=PNP0C50`，I2C 控制器 `8086:7F4F`。
- 根因：`LegionI2CArrowLake.kext` 是仅含 Info.plist 的注入项，声明 `IOClass=VoodooI2CPCILakeController`，但 VoodooI2C 2.9.1 **没有这个类**。
- 尝试过：改为 `VoodooI2CPCIController`，无效；**已撤回**，恢复原始自定义类（等待补丁版 VoodooI2C）。
- 本地共享盘、Windows、旧 EFI 克隆都没有找到补丁版；APFS 数据卷 FileVault 锁定，系统卷 sealed，Linux 只读工具读不到。
- 需在 macOS 里运行 `scripts/find-voodooi2c.sh`；若找到 `PATCHED FOUND`，把该 `VoodooI2C.kext` 复制到本文件夹，我再替换。

### 1.6 开机跑码 / OC DEBUG
- `-v` 已从 `boot-args` 移除。
- OpenCore 从 1.0.9 DEBUG 换成 1.0.9 RELEASE（Dortania 构建），替换 `OpenCore.efi`、`BOOTx64.efi`、`OpenRuntime/OpenCanopy/ResetNvramEntry/OpenLinuxBoot` 驱动；配置/kexts/Resources 保留。
- 状态：已安装，**待重启验证**；OC 阶段应不再闪代码。

### 1.7 睡眠“睡死”
- 用户确认显示由 **NVIDIA** 驱动，**不能禁用 N 卡**；`-wegnoegpu` 已加入后立即撤回，当前 `boot-args` 中没有它。
- 已提供 `scripts/fix-sleep-pmset.sh`（`hibernatemode 0`、`standby 0`、`autopoweroff 0`、`powernap 0`、`womp 0`、`proximitywake 0`、`acwake 0`）。
- 状态：**待用户在 macOS 中运行并重启测试**；如果仍睡死，运行 `scripts/diagnose-sleep.sh` 收集日志，再决定 `HibernationFixup`/`USBWakeFixup`/WiFi/音频调整。

## 2. 当前关键配置

- `Misc > Boot > Timeout = 5`
- `Misc > Debug > Target = 0`，`DisplayLevel = 0`，`AppleDebug=false`
- `Misc > Entries`：Ubuntu 项启用，Path 为完整设备路径
- `Kernel > Add` 末尾：`SimpleHDA.kext`（x86_64，25.0.0–25.99.99，启用）
- `itlwm.kext` 禁用；`UTBDefault.kext` 禁用；`SMCSuperIO.kext` 禁用
- 当前 `boot-args`：
  `-vi2c-force-polling nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4 -gux_defer_usb2 alcid=13 itlwm_he=1 keepsyms=1`
- **没有** `-wegnoegpu`；N 卡未被禁用。

## 3. 驱动版本

| 组件 | 版本 |
|---|---|
| Lilu | 1.7.3 |
| VirtualSMC / SMC 插件 | 1.3.9 |
| WhateverGreen | 1.7.2 |
| AppleALC | 1.9.9 |
| SimpleHDA | 1.0.0 |
| NVMeFix | 1.1.4 |
| RestrictEvents | 1.1.7 |
| AMFIPass | 1.4.1 |
| AirportItlwm | 2.4.0（Tahoe 构建） |
| itlwm | 2.3.0（禁用） |
| IntelBluetoothFirmware / IntelBTPatcher | 2.5.0 |
| BlueToolFixup | 2.7.3 |
| VoodooI2C | 2.9.1（官方，缺 `VoodooI2CPCILakeController`） |
| VoodooPS2Controller | 2.3.8 |
| USBMap / USBToolBox | 1.1（已改 Tahoe 键）/ 1.2.0 |
| LegionI2CArrowLake | 1.1.0（IOClass 已恢复为 `VoodooI2CPCILakeController`） |

## 4. 备份与回滚

| 备份 | 用途 |
|---|---|
| `EFI/OC-DEBUG-BACKUP-20261027-010130/` | 原 1.0.9 DEBUG 的 `OpenCore.efi`、`BOOTx64.efi`、Drivers、config |
| `EFI/OC/Kexts/AirportItlwm.kext.bak-20261027-004923/` | 原 Sequoia 构建 AirportItlwm |
| `EFI/OC/Kexts/USBMap.kext/Contents/Info.plist.bak-20261027-000217` | USBMap 改键前 |
| `EFI/OC/Kexts/LegionI2CArrowLake.kext/Contents/Info.plist.bak-20261027-005130` | 触控板原始自定义类 |
| `EFI/OC/Kexts/LegionI2CArrowLake.kext/Contents/Info.plist.bak-20261027-013237` | 触控板基类尝试版 |
| `EFI/OC/config.plist.bak-20261027-012903` | 加 `-wegnoegpu` 前 |
| `EFI/OC/config.plist.bak-20261027-013051` | 带 `-wegnoegpu` 的历史（当前已撤） |
| `previous/ZCode-Hackintosh-Session-20261027-010417.tar.gz` | 01:04 的旧导出归档 |

恢复 DEBUG OpenCore：

```bash
sudo cp EFI/OC-DEBUG-BACKUP-20261027-010130/OpenCore.efi /boot/efi/EFI/OC/OpenCore.efi
sudo cp EFI/OC-DEBUG-BACKUP-20261027-010130/BOOTx64.efi /boot/efi/EFI/BOOT/BOOTx64.efi
sudo cp EFI/OC-DEBUG-BACKUP-20261027-010130/Drivers/*.efi /boot/efi/EFI/OC/Drivers/
```

（在 Ubuntu 里把 `EFI/...` 换成 `/boot/efi/EFI/...`。）

## 5. 待验证/下一步

1. 重启验证：OC 不再跑码；WiFi/音频是否恢复；触控板是否仍无效。
2. 睡眠：在 macOS 运行 `scripts/fix-sleep-pmset.sh`，重启测试；仍睡死则运行 `scripts/diagnose-sleep.sh > ~/Desktop/sleep-log.txt` 并反馈。
3. 触控板：在 macOS 运行 `scripts/find-voodooi2c.sh`；若输出 `PATCHED FOUND`，复制该 kext 到本文件夹。
4. 若找不到补丁版 VoodooI2C：需要编译（Xcode）或先用 USB 鼠标。
5. WiFi 若未加载：`kextstat | grep -i airportitlwm`；Tahoe 版有报告要求 SIP 开启（当前 SIP 关闭）。
6. 音频若无声：试 ALC256 其他 layout（11/21/56/66/69/99），再考虑 `SimpleHDA-HAL`。

## 6. 文件夹内容

- `README.md`：本报告
- `session/`：本次会话原始模型 I/O（JSONL）及当日 CLI/APP 日志
- `EFI/`：ESP `EFI` 目录完整快照（OC、BOOT、ubuntu、OC-DEBUG-BACKUP）
- `artifacts/config/`：当前 config 和全部配置备份
- `artifacts/kext-info-backups/`：USBMap、LegionI2C 的 Info.plist 备份
- `artifacts/install-scripts/`：本次使用的安装/修改脚本
- `artifacts/packages/`：OpenCore 1.0.9 RELEASE、AirportItlwm-Tahoe、SimpleHDA 原始 zip
- `scripts/`：`fix-sleep-pmset.sh`、`diagnose-sleep.sh`、`find-voodooi2c.sh`
- `previous/`：01:04 的旧归档及校验文件
- `evidence/`：`efibootmgr`、`lsblk`、硬件、kext 版本、配置差异、OC 版本、Legion Info
- `SHA256SUMS`：本文件夹内所有文件的校验和

## 7. 参考

- OpenCore: https://github.com/acidanthera/OpenCorePkg
- Dortania builds: https://github.com/dortania/build-repo
- AirportItlwm-Tahoe: https://github.com/laobamac/itlwm
- SimpleHDA: https://github.com/laobamac/SimpleHDA
- VoodooI2C: https://voodooi2c.github.io/
