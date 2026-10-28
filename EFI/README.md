# EFI 说明

这是**实际调通并人工复核过**的 OpenCore EFI，对应：
**ASUS FX608LP**（华硕天选6 Pro）· Intel Core Ultra 9 275HX + RTX 5070 Laptop。

> ⚠️ **只适配上面这一台机器。** 换机器请重新按 RapidEFI + 人工复核的流程来，不要直接套用。

## 目录

| 路径 | 内容 |
|---|---|
| `BOOT/` | 引导入口：`BOOTx64.efi`、`fbx64.efi`、`mmx64.efi` |
| `OC/` | OpenCore 主目录 |
| `OC/config.plist` | **核心配置**（已调通） |
| `OC/OpenCore.efi` | OpenCore 本体 |
| `OC/ACPI/` | 10 个 SSDT + 本机 `DSDT.aml` |
| `OC/Drivers/` | `HfsPlus` · `OpenCanopy` · `OpenLinuxBoot` · `OpenRuntime` · `ResetNvramEntry` |
| `OC/Kexts/` | 28 个内核驱动 |
| `OC/Resources/` | 开机菜单的字体 / 图标 / 标签 |
| `OC/Tools/` | OpenCore 附带工具 |
| `ubuntu/` | Ubuntu 的 `shimx64` + `grubx64` + `mmx64`（多系统引导） |

## config.plist 关键项

| 项 | 值 | 为什么 |
|---|---|---|
| `SystemProductName` | `MacBookPro16,1` | 骗过 macOS 的机型检查 |
| `csr-active-config` | `430A0000` | 降级 SIP（装显卡驱动必需） |
| `SecureBootModel` | `Disabled` | 同上 |
| `ResizeGpuBars` | `13` | 让 2560×1600 正常出分辨率 |
| `ResizeAppleGpuBars` | `-1` | 同上 |
| Kernel → Block | `com.apple.iokit.IONDRVSupport`（Exclude） | 给第三方显卡驱动让路 |
| `boot-args` | 见根目录 README「三、驱动安装与定制」 | 显卡 / 触屏 / 声卡参数 |

## 已启用的 kext（28 项）

**基础**：`Lilu` · `VirtualSMC` · `SMCProcessor` · `SMCLightSensor` · `SMCBatteryManager`

**显卡 / 声卡**：`WhateverGreen` · `AppleALC`（`alcid=13`）
（NVIDIA 独显走 1401 驱动，**不是** kext，见根目录 README）

**无线 / 蓝牙**：`AirportItlwm`（Intel AX210）· `IntelBluetoothFirmware` · `IntelBTPatcher` · `BlueToolFixup`

**有线 / 存储**：`RealtekRTL8111` · `NVMeFix`

**输入**：`VoodooI2C`（+`VoodooGPIO` / `VoodooI2CServices` / `VoodooInput`）· `VoodooI2CHID` ·
`VoodooPS2Controller`（+`Keyboard` / `Mouse` / `Trackpad`）

> 触控板已使用补丁版 `VoodooI2C` / `VoodooI2CHID`（强制 Polling + 定时器），详见根目录 README「13.1 触控板」。

**USB**：`USBToolBox` · `USBMap`

**CPU / 其它**：`CpuTscSync` · `CpuTopologyRebuild` · `AMFIPass` · `AppleMCEReporterDisabler` ·
`RestrictEvents` · `BrightnessKeys` · `LegionI2CArrowLake`

> **关闭的三项**：`SMCSuperIO`、`UTBDefault`、`itlwm`
> （`itlwm` 与 `AirportItlwm` **二选一**，当前用 `AirportItlwm`；两项同时开会冲突）

## 使用前必做

1. **重新生成 SMBIOS** —— 仓库里的 `SystemSerialNumber` / `MLB` / `SystemUUID` / `ROM`
   已替换为占位符。请在 OCAT / GenSMBIOS 里生成一套你自己的，不要直接使用占位符；
   多台机器共用同一套会导致 iCloud / iMessage 被锁。
2. **改 BIOS**：关 Secure Boot、关 VT-d、开 Resizable BAR、开 Above 4G、开独显直连。
3. **确认 macOS 版本**：这份 `EFI/` 原始配置对应 **macOS 15.7.8**；macOS 26 完整 EFI 见 `macos26/EFI/`，当前配置和触控板补丁见根目录 README 第十二节 / 0.1。
4. 先在小容量 U 盘上试，别一上来就动主硬盘。

## 关于备份文件

原始目录里有 18 个 `config.plist.bak-*`（每轮调试的存档）和一个 2.4 MB 的
`Background.icns.bak-*`，这些**没有上传** —— 需要看调试过程可以翻 git 提交记录。
