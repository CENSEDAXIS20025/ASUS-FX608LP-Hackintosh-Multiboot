# EFI-当前可用-20261030

**这是 2026-10-30 时我正在用的、能正常开机的 EFI。**

| 项 | 值 |
|---|---|
| 机器 | ASUS FX608LP（华硕天选 6 Pro）· Intel Core Ultra 9 275HX · RTX 5070 Laptop |
| 系统 | **macOS 26.7.1**（25G241）· Ubuntu 26.04 LTS · Windows 11 三系统共存 |
| OpenCore | **1.0.9 RELEASE**（`OpenCore.efi` 616 KB，非 DEBUG 版） |
| SMBIOS | `MacBookPro16,1`（序列号已脱敏为占位符，**请自行生成**） |
| 日志 | `Misc → Debug → Target = 0`、`DisplayLevel = 0`、`AppleDebug/ApplePanic = false`（**不开 OC 日志，不跑码**） |

## 内容

```
BOOT/                      引导入口（BOOTx64.efi 等）
OC/                        OpenCore 主目录
  config.plist             核心配置（当前可用）
  OpenCore.efi             1.0.9 RELEASE
  ACPI/                    SSDT 补丁
  Drivers/                 UEFI 驱动
  Kexts/                   内核驱动
  Resources/               开机菜单资源
  Tools/                   OC 工具
ubuntu/                    Ubuntu 的 shim + grub（多系统引导用）
```

## 已剔除

为了让仓库干净，**没有上传**这些备份文件（它们还留在原机的 `C:\Users\ASUS\Desktop\EFI` 里）：

- `config.plist.bak-*`（历次调参备份，34 个）
- `*.kext.bak-*`（旧版 AirportItlwm、VoodooI2C、VoodooI2CHID 等）
- `Background.icns.bak-*`
- `oldConfig.plist`
- `OC-DEBUG-BACKUP-20261027-010130/`（DEBUG 版 OpenCore 备份）

## 使用前必读

1. **只适配 ASUS FX608LP 这一台机器**，换机器请重新生成
2. **SMBIOS 序列号是占位符**，务必自己生成一套（OCAT / GenSMBIOS）
3. 用之前先确认 BIOS 设置：关 Secure Boot、关 **Intel TXT**、关 VT-d、开 Resizable BAR、开 Above 4G、开独显直连
4. 备份好现有 EFI 再替换
