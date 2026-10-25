# 天选6pro 黑苹果等多系统安装案例

华硕天选6 Pro（ASUS TUF Gaming F16 / **FX608LP**）上跑 **macOS 15.7.8 黑苹果 + Ubuntu 26.04 LTS + Windows** 多系统共存的完整安装记录，含可直接取用的 OpenCore EFI。

**本仓库只记录我这一台机器上实际跑通的过程。** 换一台机器，绝大多数东西都要重新调。

> 📅 记录时间：2026 年 10 月
> 💻 测试系统：macOS **15.7.8**（Sequoia）· Ubuntu **26.04 LTS** · Windows 11

---

## ⚠️ 重要声明（务必先读）

**1. 显卡驱动是转载，不是我写的**

macOS 下的 NVIDIA 驱动来自开源项目 **1401 / nullmoth**：

- 驱动仓库：<https://github.com/nullmoth/nvidia-macos-driver>
- 1401 项目：<https://github.com/nullmoth/1401>

**本仓库不包含该驱动的任何源码，也没有对它做任何修改**，只是记录「我用它跑通了」这件事并给出安装步骤。驱动的版权、署名、授权全部归原作者 **nullmoth** 及 1401 项目贡献者所有。使用前请到上面两个仓库阅读其许可证与说明。

**2. 只在我的硬件上验证过**

下面的 EFI、ACPI、USB 定制、SMBIOS 全部是为这一台机器调的。**别的机器直接用大概率开不了机**，最坏情况会清掉你的引导项。请把它当作「参考案例」，而不是「通用 EFI」。

**3. 风险自负**

黑苹果需要关闭 Secure Boot、修改 SIP、打内核补丁、屏蔽核显。可能造成：数据丢失、系统无法启动、Windows 蓝屏、失去保修、iCloud/iMessage 账号异常。**请先备份，重要数据不要只存一份。**

**4. 不含任何 Apple 受版权保护的内容**

仓库里没有 macOS 安装镜像、没有 Apple 的驱动文件。系统镜像请自行通过 Apple 官方渠道获取。

**5. 请自己生成 SMBIOS**

`config.plist` 里的序列号（`SystemSerialNumber` / `MLB` / `SystemUUID`）是我随机生成的，**请务必用 OCAT 或 GenSMBIOS 重新生成一套你自己的**，不要直接沿用 —— 多台机器共用同一套序列号会导致 iCloud / iMessage 被锁。

---

## 硬件信息

| 部件 | 型号 | macOS 下状态 |
|---|---|---|
| 整机 | **ASUS TUF Gaming F16（FX608LP）** / 华硕天选6 Pro | — |
| CPU | **Intel Core Ultra 9 275HX**（Arrow Lake-HX，24 核 8P+16E，无超线程） | ✅ 需 CPUID 伪装 + CpuTopologyRebuild |
| 核显 | Intel Graphics（`8086:7D67`，Xe-LPG，Arrow Lake-H/HX） | ❌ macOS 无驱动，**已屏蔽** |
| 独显 | **NVIDIA GeForce RTX 5070 Laptop**（GB206，`10DE:2D58`，支持 MUX 独显直连） | ⚠️ 靠 1401 驱动 |
| 无线 | Intel Wi-Fi 6E **AX210**（`8086:2725`） | ✅ AirportItlwm |
| 蓝牙 | Intel 蓝牙（走 USB） | ✅ IntelBluetoothFirmware + BlueToolFixup |
| 声卡 | Realtek **ALC256** | ✅ AppleALC（`alcid=13`） |
| 有线网卡 | Realtek **RTL8168** | ✅ RealtekRTL8111 |
| 屏幕 | 2560 × 1600 | ✅ 需 `ResizeGpuBars=13` |
| 硬盘 | NVMe SSD | ✅ 需 NVMeFix |
| 电池 | ASUS GU60558 | ✅ SMCBatteryManager |

**SMBIOS 机型：`MacBookPro16,1`**（这是为了骗过 macOS 的机型检查，不代表真实硬件）

---

## 一、Windows + Ubuntu 26.04 LTS（Intel 新平台）

> 顺序建议：**先装 Windows，再装 Ubuntu**。装完 Windows 再动分区，引导关系更清楚。

### 1. 下载系统镜像

Ubuntu 26.04 LTS Desktop：<https://ubuntu.com/download/desktop>

### 2. 烧录到 U 盘

用 **balenaEtcher**：<https://etcher.balena.io/>

### 3. 硬盘分区

进 PE，用 **DiskGenius**：<https://www.diskgenius.com/>

给 Ubuntu 留出未分配空间（建议 ≥ 80 GB）。

### 4. BIOS 设置

- 关闭 **Secure Boot**
- 关闭 **Intel RST**（或在 RAID 模式下切到 AHCI）
- 关闭 **Windows BitLocker**（控制面板 → 设备加密）

### 5. 确认硬盘控制器类型

在 Windows 里看硬盘控制器是不是 **AHCI**、有没有开 **VMD**。

### 6. ⚠️ 关闭 VMD（Intel 新平台必做，否则改 BIOS 会蓝屏）

**先备份注册表**，然后按 Ubuntu 官方教程改：

<https://ubuntu.com/desktop/docs/en/26.04/how-to/reconfigure-windows-to-use-ahci/>

> **官方教程漏了 NVMe！** 除了教程里写的 `stornvme`，NVMe 硬盘还要改
> `HKLM\SYSTEM\CurrentControlSet\Services\stornvme` 下的 `StartOverride`。
> 改完**必须进一次安全模式**强制切换驱动，否则重启直接蓝屏。

### 7. 进安全模式验证

进安全模式前，先在 BIOS 里关闭 **VMD**（或把硬盘控制器切成 **AHCI**），
重启后确认设备管理器里已经变成「标准 NVM Express 控制器」。

### 8. 从 U 盘启动，安装 Ubuntu

- **不要勾选任何「在线下载」相关的选项**（会卡网络）
- 如果机器**没有核显**（或核显被禁用），启动界面选第二项 **safe boot**

### 9. 分区

选中你留出的空闲空间 → 点左下角 **「+」**：

- 挂载点选 **`/`**
- 引导加载器安装位置选**这块硬盘**

> **不推荐**把 Ubuntu 的 EFI 分区和 Windows 的 EFI 分区合并共存，容易把 Windows 引导搞坏。

### 10. 完成设置

---

## 二、macOS 15.7.8 黑苹果

### 1. 开启独显直连

BIOS 里把显示输出切到 **独显直连（MUX / Discrete GPU only）**。
核显在 macOS 下没有驱动，必须屏蔽，否则会黑屏或卡进度条。

### 2. 用 RapidEFI 生成 EFI

<https://github.com/JeoJay127/RapidEFI-Tool>

选对应机型后生成。**注意：一定要人工复核！** 自动生成的配置不能直接信，尤其是：

- **屏蔽核显**（`-wegnoegpu` 或设备属性里禁用 iGPU）
- CPUID 伪装（Arrow Lake 需要）
- SMBIOS 机型

> 本仓库 `EFI/` 里就是我**复核并调通之后**的成品，可以直接对比。

### 3. 烧录 macOS 镜像

用 **balenaEtcher** 把 dmg 烧到 U 盘（镜像自行获取）。

### 4. 替换 U 盘 EFI

用 **DiskGenius** 打开 U 盘的 EFI 分区，用第 2 步生成的 EFI 替换掉原有的。

### 5. BIOS 检查

| 项 | 设置 |
|---|---|
| Secure Boot | **关闭** |
| VT-d | **关闭**（不关会卡 EB） |
| Resizable BAR | **开启** |
| Above 4G Decoding | **开启** |
| 独显直连 | **开启** |

### 6. 从 U 盘启动

进 OpenCore 界面 → 选 **Install macOS**。

> **卡住就停下来查，不要反复重试。** 跑码卡住 99% 是 EFI 配置问题。

### 7. 跑码阶段的问题处理

**遇到任何报错，拍照，然后和 AI 一起排查。** 两个最高发的失败点：

- **卡 `EB`** → 几乎都是 **VT-d 没关**
- **乱码 + 禁止符号（🚫）** → **USB 端口没有定制**（见下面 FAQ）

### 8. 抹盘

进入系统 → **磁盘工具** → 选中要装 macOS 的磁盘 → 右键 **抹掉** → 格式选 **APFS**。

### 9. 安装

退出磁盘工具 → 选 **安装 macOS 15** → 选安装盘 →
后面会**多次重启**，每次都选 **macOS Installer** 那个启动项，直到进入系统。

> - 中途跑码卡住 = EFI 问题，回去重新配
> - **每次都要从 U 盘启动**（装好之前硬盘引导还没写好）

---

## 三、驱动安装与定制（NVIDIA 独显）

这一步是让 **RTX 5070** 在 macOS 下亮起来的关键。

### 1. 打开 OCAT

<https://github.com/ic005k/OCAuxiliaryTools>

挂载 **ESP 分区**，加载 `EFI/OC/config.plist`。

### 2. 改这些项

**NVRAM → 7C436110-AB2A-4BBB-A880-FE41995C9F82**

- `csr-active-config` → `430A0000`
- `boot-args` →

```
-vi2c-force-polling nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4 -gux_defer_usb2 -v keepsyms=1 alcid=13
```

**UEFI → Quirks**

- `ResizeGpuBars` → `13`

**Booster → Quirks**

- `ResizeAppleGpuBars` → `-1`

**Kernel → Block**（新增一条）

- `Identifier` = `com.apple.iokit.IONDRVSupport`
- `Strategy` = `Exclude`
- 勾选 **Enabled**

**Misc → Security**

- `SecureBootModel` = `Disabled`

### 3. 安装 1401 驱动

下载：<https://github.com/nullmoth/nvidia-macos-driver>

打开终端，逐条运行：

```bash
cd （把解压后的目录拖进终端，去掉文件名，保留路径，回车）
tar -xzf nullmoth-nvidia-*.tar.gz && cd pkgroot
shasum -a 256 -c SHA256SUMS
sudo ./install.sh
```

然后：

1. 在 **系统设置** 里同意隐私/安全弹窗
2. `sudo shutdown -r now` 重启

> ⚠️ 驱动来自开源项目，**仅支持 macOS 15 Sequoia**（15.x），且要求 Secure Boot 关闭 / SIP 已降级。
> 版本更新和授权请以作者仓库为准，本仓库不转存、不修改、不分发其任何文件。

---

## 四、引导设置（让 EFI 出现在 BIOS 启动项里）

### 1. 准备

用 **EasyUEFI**：<https://www.easyuefi.com/>

先确认 EFI 文件已经复制到 **ESP 分区**。

### 2. 添加引导项

1. 打开 EasyUEFI → **管理 EFI 启动项** → **新建**
2. 选 **ESP 分区**，类型选 **Linux 及其他**
3. 文件路径填 `EFI\BOOT\bootx64.efi`
4. 保存，然后在 BIOS 或软件里把它的顺序调到第一位

---

## 五、还原 U 盘

装完之后把 U 盘还原成普通 U 盘（**会清空整个 U 盘**，先确认盘号！）：

```
diskpart
list disk
select disk 2
clean
```

> `select disk 2` 里的 **2 一定要换成你 U 盘的盘号**，选错会清掉你的硬盘。

---

## 六、双系统时间同步

Windows 默认把 BIOS 时间当本地时间，Linux/macOS 当 UTC，所以切系统会差 8 小时。

**在 Windows 里用管理员权限运行：**

```cmd
reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
```

---

## 七、EFI 说明

### 目录结构

```
EFI/
├── BOOT/            BOOTx64.efi · fbx64.efi · mmx64.efi
├── OC/              OpenCore 主目录
│   ├── config.plist   ← 核心配置（已调通）
│   ├── OpenCore.efi
│   ├── ACPI/          10 个 SSDT + DSDT.aml
│   ├── Drivers/       HfsPlus · OpenCanopy · OpenLinuxBoot · OpenRuntime · ResetNvramEntry
│   ├── Kexts/         28 个驱动（见下表）
│   ├── Resources/     开机菜单的字体、图标、标签
│   └── Tools/
└── ubuntu/          Ubuntu 的 shim + grub（多系统引导）
USB定制/             usb.json（端口数据）· settings.json · USBMap.kext
```

### 已启用的 kext（28 项）

| kext | 作用 |
|---|---|
| Lilu | 几乎所有其它 kext 的基础 |
| VirtualSMC | 模拟 SMC 芯片（黑苹果必备） |
| SMCProcessor · SMCLightSensor · SMCBatteryManager | CPU 传感器 · 环境光 · 电池 |
| WhateverGreen | 显卡通用补丁 |
| AppleALC | 声卡（`alcid=13`） |
| AirportItlwm | Intel AX210 无线网卡 |
| IntelBluetoothFirmware · IntelBTPatcher · BlueToolFixup | Intel 蓝牙 |
| RealtekRTL8111 | 有线网卡 |
| NVMeFix | NVMe 电源管理 |
| USBToolBox · USBMap | USB 端口定制 |
| VoodooI2C · VoodooI2CHID · VoodooGPIO · VoodooI2CServices | 触摸板（I2C） |
| VoodooPS2Controller（+Keyboard/Mouse/Trackpad） | 键盘 / 触摸板回退 |
| CpuTscSync · CpuTopologyRebuild | TSC 同步 · 大小核拓扑修正 |
| AMFIPass | 部分场景替代 AMFI 补丁 |
| AppleMCEReporterDisabler | 关掉 MCE 报错 |
| RestrictEvents | 屏蔽部分机型检测 |
| BrightnessKeys | 亮度快捷键 |
| LegionI2CArrowLake | I2C 触摸板适配（Arrow Lake 平台） |

**关闭的**：`SMCSuperIO`、`UTBDefault`、`itlwm`（与 AirportItlwm 二选一，当前用 AirportItlwm）。

### 关键参数

| 项 | 值 |
|---|---|
| SMBIOS | `MacBookPro16,1` |
| `csr-active-config` | `430A0000`（降级 SIP） |
| `SecureBootModel` | `Disabled` |
| `ResizeGpuBars` / `ResizeAppleGpuBars` | `13` / `-1` |
| Kernel Block | `com.apple.iokit.IONDRVSupport`（Exclude，启用） |
| `boot-args` | 见上面「三、驱动安装与定制」 |

---

## 八、常见问题 FAQ

### 卡在 `EB`（`EB.WL.PWLFNV` 之类）

**VT-d 没关。** 进 BIOS 关掉 VT-d（或 `VT for Directed I/O`），这是最高发的原因。

### 乱码 + 禁止符号 🚫

**USB 端口没定制**，或者 USB 相关 SSDT/kext 不对。

- 用 **USBToolBox** 重新定制：<https://github.com/USBToolBox/tool>
- 或在 BIOS 里临时把 `XHCI Hand-off` 打开应急

### 卡在 `Still waiting for root device`

找不到启动盘。常见原因：NVMe 没驱动、USB 口用了不支持的控制器、`SecureBootModel` 没关。

### 装完重启进不了系统 / 反复重启

- 每次重启都要**从 U 盘启动**，选 `macOS Installer` 继续
- 装完第一次进桌面之前，不要拔 U 盘

### 独显不亮 / 黑屏

按顺序检查：

1. BIOS 里**独显直连**开了吗
2. `ResizeGpuBars=13`、`ResizeAppleGpuBars=-1` 设了吗
3. Kernel Block 里 `IONDRVSupport` 加了吗
4. `SecureBootModel=Disabled` 了吗
5. 1401 驱动装了吗、装完重启了吗

### 屏幕分辨率不对（没有 2560×1600）

`ResizeGpuBars` 没设成 `13`，或者 `ResizeAppleGpuBars` 不是 `-1`。

### 改了 BIOS 之后 Windows 蓝屏 `INACCESSIBLE_BOOT_DEVICE`

**VMD / RST 模式变了。** 回 BIOS 改回来，或按「一、第 6 步」改注册表后进安全模式切换。

### 切系统时间差 8 小时

见上面「六、双系统时间同步」。

### Wi-Fi 打不开

- 确认 `AirportItlwm` 是**启用**的、`itlwm` 是**关闭**的（两个不能同时开）
- AirportItlwm 版本要和 macOS 版本对应（15.x 要用对应版本）
- AX210 在部分 macOS 版本下还需要配合 `itlwm` + **HeliPort** 客户端：
  <https://github.com/OpenIntelWireless/HeliPort>

### 声卡没声音

`boot-args` 里的 `alcid=` 编号不对。ALC256 常用 `13`，也可以试 `11`、`21`、`69`，逐个试。

### 睡眠 / 唤醒异常

先用 `pmset -g log` 看唤醒原因；常见是 USB 设备唤醒或 `Hibernatemode` 设置问题。
可以先把「显示器睡眠」关掉，只留「系统睡眠」逐个排查。

---

## 九、用到的软件与驱动（官网）

| 软件 | 用途 | 官方地址 |
|---|---|---|
| Ubuntu Desktop | 系统镜像 | <https://ubuntu.com/download/desktop> |
| balenaEtcher | 烧录 ISO / DMG 到 U 盘 | <https://etcher.balena.io/> |
| DiskGenius | 分区管理 / 编辑 EFI | <https://www.diskgenius.com/> |
| OpenCorePkg | OpenCore 引导器本体 | <https://github.com/acidanthera/OpenCorePkg> |
| OCAuxiliaryTools (OCAT) | OpenCore 图形化配置 | <https://github.com/ic005k/OCAuxiliaryTools> |
| RapidEFI-Tool | 自动生成机型 EFI | <https://github.com/JeoJay127/RapidEFI-Tool> |
| Dortania OpenCore Guide | 黑苹果权威教程 | <https://dortania.github.io/OpenCore-Install-Guide/> |
| **nvidia-macos-driver（1401）** | **NVIDIA 显卡驱动（转载来源）** | <https://github.com/nullmoth/nvidia-macos-driver> |
| **1401** | **NVIDIA 驱动项目主页** | <https://github.com/nullmoth/1401> |
| EasyUEFI | 管理 UEFI 启动项 | <https://www.easyuefi.com/> |
| USBToolBox | USB 端口定制 | <https://github.com/USBToolBox/tool> |
| HeliPort | itlwm 的 Wi-Fi 客户端 | <https://github.com/OpenIntelWireless/HeliPort> |

**Kext 来源**（绝大多数是 Acidanthera 官方开源项目）：

| kext | 仓库 |
|---|---|
| Lilu · VirtualSMC · WhateverGreen · AppleALC · NVMeFix · RestrictEvents · BrightnessKeys · AppleMCEReporterDisabler · CpuTscSync · VoodooPS2 | <https://github.com/acidanthera> |
| AirportItlwm · itlwm | <https://github.com/OpenIntelWireless/itlwm> |
| IntelBluetoothFirmware · IntelBTPatcher | <https://github.com/OpenIntelWireless/IntelBluetoothFirmware> |
| VoodooI2C · VoodooI2CHID | <https://github.com/VoodooI2C/VoodooI2C> |
| RealtekRTL8111 | <https://github.com/Mieze/RTL8111_driver_for_OS_X> |
| USBToolBox · USBMap | <https://github.com/USBToolBox/kext> |
| CpuTopologyRebuild | <https://github.com/b00t0x/CpuTopologyRebuild> |

---

## 十、目录说明

| 路径 | 内容 |
|---|---|
| `README.md` | 本文档（安装教程） |
| `安装Windows+其他多系统.txt` | 我最初的原始笔记（未整理版） |
| `EFI/` | 调通的 OpenCore EFI（可直接对比参考） |
| `USB定制/` | USB 端口数据（`usb.json`）与 `USBMap.kext` |
| `session-log/` | 这次折腾的完整 AI 对话日志（含排查过程） |

---

## 最后再说一次

1. **显卡驱动是 nullmoth / 1401 的，我只是转载记录**，版权归原作者
2. **EFI 只适配 ASUS TUF Gaming FX608LP 这一台机器**
3. **SMBIOS 序列号请自己生成**，不要照抄
4. 黑苹果有风险，**先备份**
5. macOS 是 Apple 的版权软件，本仓库不含任何系统文件

祝你好运 🍀
