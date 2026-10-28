> 本文由 deepseek-flash 上传。

# ASUS FX608LP（天选 6 Pro）黑苹果多系统安装与维护记录

**ASUS FX608LP**（华硕天选 6 Pro）上跑 **macOS 26.7.1 + Ubuntu 26.04 LTS + Windows 11** 多系统共存的实机记录，含可直接取用的 OpenCore EFI、踩坑过程和修复方案。

> **这是我的踩坑记录，希望能帮上大家。**

> 记录时间：2026 年 10 月
> 当前测试系统：macOS **26.7.1（25G241）** · Ubuntu **26.04 LTS** · Windows 11
> 机器：Intel Core Ultra 9 275HX · RTX 5070 Laptop · 32 GB · 2560×1600 165 Hz

> **本仓库只记录这一台机器上实际跑通的过程。** 换一台机器，绝大多数东西都要重新调。

> **外部链接声明**：本文引用了大量外部资料（OpenCore、VoodooI2C、1401/NVIDIA、maclator、AsusSMC、BetterDisplay 等），所有链接均在文末「外部引用链接」统一列出，正文中也会标注；版权归各自作者所有，本仓库只记录链接和实机结论，不转载正文。若链接内容侵犯权益，请在 Issues 提出，我会立即移除。

> **SMBIOS 声明**：仓库里的 `SystemSerialNumber`、`MLB`、`SystemUUID`、`ROM` 已全部替换为占位符（`XXXXXXXXXXXX` / `XXXXXXXXXXXXXXXXX` / 全 0 UUID / 全 0 ROM）。**请务必用 OCAT、GenSMBIOS 或 OpenCore Configurator 生成一套你自己的序列号**，不要直接使用占位符，也不要多台机器共用同一套，否则 iCloud / iMessage 可能被锁。2026-10-28 已对当前文件和 git 历史做过脱敏；如果你在 fork、缓存或旧 commit 里看到旧值，请以本仓库最新 `main` 为准。

## 目录

**系统安装**

- [一、Windows + Ubuntu 26.04 LTS（Intel 新平台）](#sec1)
- [二、macOS 15.7.8 黑苹果](#sec2)
- [三、驱动安装与定制（NVIDIA 独显）](#sec3)
- [四、引导设置（让 EFI 出现在 BIOS 启动项里）](#sec4)
- [五、还原 U 盘](#sec5)
- [六、双系统时间同步](#sec6)
- [七、EFI 说明](#sec7)
- [八、常见问题 FAQ](#sec8)
- [九、延伸阅读（详细教程）](#sec9)
- [十、用到的软件与驱动（官网）](#sec10)
- [十一、目录说明](#sec11)
- [十二、macOS 26（Tahoe）迁移记录](#sec12)

**安装后的维护与修复**

- [十三、安装后的维护与修复（2026-10-28）](#maintenance)
  - [13.1 触控板（重点，已解决）](#touchpad)
  - [13.2 1401 EFI 检查 4 项](#efi-checks)
  - [13.3 睡眠 / 休眠（已解决）](#sleep)
  - [13.4 键盘、Fn、AsusSMC、键盘背光、Fn+F10](#keyboard)
  - [13.5 风扇与功耗](#fan)
  - [13.6 显示缩放 / HiDPI](#scaling)
  - [13.7 网页滚动破碎 / 渲染异常](#render)
  - [13.8 maclator 部署与使用](#maclator)
  - [13.9 菜单栏图标间距](#menubar)
  - [13.10 当前状态：已解决 / 未解决](#status)
  - [13.11 备份、恢复与 SMBIOS](#backup)

**声明**

- [十四、声明与致谢 / 外部引用链接](#sec14)

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

**5. SMBIOS 已脱敏，请自己生成**

仓库里的 `SystemSerialNumber`、`MLB`、`SystemUUID`、`ROM` 已替换为占位符（`XXXXXXXXXXXX` / `XXXXXXXXXXXXXXXXX` / 全 0 UUID / 全 0 ROM）。**请务必用 OCAT、GenSMBIOS 或 OpenCore Configurator 重新生成一套你自己的**，不要直接使用占位符，也不要多台机器共用同一套 —— 会导致 iCloud / iMessage 被锁。2026-10-28 已对当前文件和 git 历史做脱敏；如果你在 fork、缓存或旧 commit 里看到旧值，请以最新 `main` 为准。

---

## 硬件信息

| 部件 | 型号 | macOS 下状态 |
|---|---|---|
| 整机 | **ASUS FX608LP**（华硕天选6 Pro） | — |
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
| 触控板 | **ELAN `04F3:32E2`**（I2C-HID，I2C 地址 `0x15`） | ✅ **已修复**：补丁版 VoodooI2C + VoodooI2CHID（见 [13.1 触控板](#touchpad)） |

**SMBIOS 机型：`MacBookPro16,1`**（这是为了骗过 macOS 的机型检查，不代表真实硬件）

---

<a name="sec1"></a>
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

<a name="sec2"></a>
## 二、macOS 15.7.8 黑苹果

### 1. 开启独显直连

BIOS 里把显示输出切到 **独显直连（MUX / Discrete GPU only）**。
核显在 macOS 下没有驱动，必须屏蔽，否则会黑屏或卡进度条。

### 2. 生成 EFI：RapidEFI 或 1401

有两条路可以走，**我最后用的是 1401**。

#### 方案 A · RapidEFI

<https://github.com/JeoJay127/RapidEFI-Tool>

选对应机型后生成，然后自己再烧 macOS 镜像（见第 3 步）。

> ⚠️ **RapidEFI 没有第 15 代（Arrow Lake / Core Ultra 200）处理器的模板** ——
> 选不到能对得上的机型，这也是我最后没用它的原因。

#### 方案 B · 1401（我实际用的，新平台推荐）

<https://github.com/nullmoth/1401>

Windows 下的开源工具：检查硬件 → 生成 OpenCore →（可选）下载 macOS 并写 U 盘。
它基于 [OpCore-Simplify](https://github.com/lzhoang2801/OpCore-Simplify) 再套自己的规则，
**专门带了 Arrow Lake 的处理**（`arrow-lake-ctr` / `arrow-lake-ctrsmt`），所以第 15 代平台能用。

> 💡 **我只用了它的「生成 EFI」这一步** —— `Create the macOS stick` 没走，
> 生成完直接退出程序，然后去它的构建目录把 EFI 捞出来，后面照常用自己的镜像。

用法：

1. 解压 release，保持 `1401` 文件夹完整，**以管理员身份运行 `1401.exe`**
2. 依次点：**Check this PC** → **Build the Mac setup**（这一步就已经把 EFI 生成好了）
3. **到这儿就可以退出程序了**
4. 打开构建目录拿 EFI —— **`%LOCALAPPDATA%\NullMoth\1401\efi\`**
   - 资源管理器地址栏直接粘 `%LOCALAPPDATA%\NullMoth\1401\efi` 回车即可
   - 里面有个 **`EFI`** 文件夹（含 `EFI\OC\config.plist`、`EFI\BOOT\…`），**整个拷出来备用**
5. 拿到 EFI 后，回到下面第 3、4 步：自己烧 macOS 镜像 → 用它替换 U 盘的 EFI

> ⚠️ **不要点 `Create the macOS stick`** —— 那一步会**清空整支 U 盘并联网下载 macOS**。
> 只想取 EFI 的话，到第 3 步退出就行，U 盘和镜像都用你自己的。

#### 无论用哪个：一定要人工复核！

自动生成的配置不能直接信，重点检查：

- **屏蔽核显**（`-wegnoegpu` 或设备属性里禁用 iGPU）
- CPUID 伪装（Arrow Lake 需要）
- SMBIOS 机型

> 本仓库 `EFI/` 里就是我**复核并调通之后**的成品，可以直接对比。

### 3. 烧录 macOS 镜像

用 **balenaEtcher** 把 dmg 烧到 U 盘（镜像自行获取）。

> 只有走 1401 的 `Create the macOS stick` 才不用这步；像我一样只取 EFI 的，这步照常做。

### 4. 替换 U 盘 EFI

用 **DiskGenius** 打开 U 盘的 EFI 分区，用第 2 步拿到的 EFI 替换掉原有的。

> 用 1401 的 `Create the macOS stick` 写盘的话，EFI 已经一起写进去了，这步跳过。

### 5. BIOS 检查

| 项 | 设置 |
|---|---|
| **Intel 可信执行技术（Intel TXT）** | **先关闭** ← 天选的 VT-d 被 TXT 锁着，不先关它 VT-d 关不掉 |
| Secure Boot | **关闭**（直接关「安全启动控制」，重进 BIOS 会看到 Secure Boot 已自动变成关闭） |
| VT-d | **关闭**（不关会卡 EB） |
| Resizable BAR | **开启** |
| Above 4G Decoding | **开启** |
| 独显直连 | **开启** |

> 📌 **天选这台的正确顺序：关「安全启动控制」→ 关「Intel TXT」→ 关 VT-d。**
> 顺序错了 VT-d 会灰着改不了。

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

<a name="sec3"></a>
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
-vi2c-force-polling nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4 -gux_defer_usb2 alcid=13 itlwm_he=1 keepsyms=1 -ibtcompatbeta revpatch=sbvmm,cpuname
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

> **下载后不要手动解压**（不要用解压软件双击它），下面的 `tar` 命令会自己解开。

打开「终端」，按顺序做三步：

```bash
# ① 把下载好的 nullmoth-nvidia-*.tar.gz 拖进终端窗口，
#    然后删掉末尾的文件名，只保留它所在的目录路径，回车
cd /拖进来的目录路径/

# ② 解包并进入 pkgroot（校验和安装都在这一层做）
tar -xzf nullmoth-nvidia-*.tar.gz && cd pkgroot

# ③ 先校验完整性，再安装
shasum -a 256 -c SHA256SUMS
sudo ./install.sh
```

装完之后：

1. 在 **系统设置** 里同意隐私 / 安全弹窗
2. `sudo shutdown -r now` 重启

> ⚠️ 驱动来自开源项目，**仅支持 macOS 15 Sequoia**（15.x），且要求 Secure Boot 关闭 / SIP 已降级。
> 版本更新和授权请以作者仓库为准，本仓库不转存、不修改、不分发其任何文件。

---

<a name="sec4"></a>
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

<a name="sec5"></a>
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

<a name="sec6"></a>
## 六、双系统时间同步

Windows 默认把 BIOS 时间当本地时间，Linux/macOS 当 UTC，所以切系统会差 8 小时。

**在 Windows 里用管理员权限运行：**

```cmd
reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
```

---

<a name="sec7"></a>
## 七、EFI 说明

> ⚠️ **这份 `EFI/` 只适用于 macOS 15（Sequoia）。**
> macOS 26（Tahoe）改了不少底层的东西 —— USB 端口属性名变了、`AppleHDA.kext` 被移除、无线驱动要换 Tahoe 构建，
> **必须重新定制 USB / 网卡 / 声卡**。我后来在 macOS 26 上的完整踩坑记录见
> 「[十二、macOS 26（Tahoe）迁移记录](#十二macos-26tahoe迁移记录)」。

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
| `ProcessorType` | `0`（自动） |
| `revpatch` | `sbvmm,cpuname` |
| `revcpu` / `revcpuname` | `1` / `Intel Core Ultra 9 275HX`（RestrictEvents 1.1.7） |
| `csr-active-config` | `430A0000`（降级 SIP） |
| `SecureBootModel` | `Disabled` |
| `ResizeGpuBars` / `ResizeAppleGpuBars` | `13` / `-1` |
| Kernel Block | `com.apple.iokit.IONDRVSupport`（Exclude，启用） |
| `boot-args` | 见上面「三、驱动安装与定制」 |

---

<a name="sec8"></a>
## 八、常见问题 FAQ

### 卡在 `EB`（`EB.WL.PWLFNV` 之类）

**VT-d 没关。** 进 BIOS 关掉 VT-d（或 `VT for Directed I/O`），这是最高发的原因。

> ⚠️ **天选6 Pro 上关不掉 VT-d？先关「Intel 可信执行技术（Intel TXT）」。**
> 这台机器的 VT-d 被 TXT 锁着，正确顺序是：**关「安全启动控制」→ 关 Intel TXT → 关 VT-d**。
> 关掉「安全启动控制」后重进 BIOS，Secure Boot 会自己变成关闭状态。

### 乱码 + 禁止符号 🚫

**USB 端口没定制**，或者 USB 相关 SSDT/kext 不对。

- 用 **USBToolBox** 重新定制：<https://github.com/USBToolBox/tool>
- 或在 BIOS 里临时把 `XHCI Hand-off` 打开应急

### 跑码卡住 / 装完反复重启

- **跑码卡住 = EFI 问题**，回去重新配 EFI
- 安装过程会**多次重启**，每次都要从 **U 盘启动**，选 `macOS Installer` 继续
- 装完第一次进桌面之前，**不要拔 U 盘**

### 改了 BIOS 之后 Windows 蓝屏 `INACCESSIBLE_BOOT_DEVICE`

**VMD / RST 模式变了。** 回 BIOS 把硬盘控制器改回来，
或按「一、第 6 步」改注册表后进安全模式切换。

### 切系统时间差 8 小时

见「六、双系统时间同步」。

> 上面四条是我这次实际踩到的。其它报错的详细排查，见下面「九、延伸阅读」。

---

<a name="sec9"></a>
## 九、延伸阅读（详细教程）

这三份是我自己查得最多的，内容比本文细得多。**遇到本文没写到的报错，先去这里找。**

| 来源 | 内容 |
|---|---|
| [黑苹果屋 · OpenCore 引导各种卡 & 常见问题速查表合集](https://imacos.top/2021/01/19/0154/) | **按报错原文分类的速查表**：`OCB: StartImage failed`、`OCABC: Memory pool allocation failure`、`apfs_module_start`、禁止符号、黑屏、卡 EB…… 一条条给解决方案。适合拿着屏幕上的报错直接搜。 |
| [黑苹果星球 · OpenCore 安装卡住的拯救手册 Q&A](https://heipg.cn/tutorial/opencore-install-errors-handbook.html) | **Q&A 式的系统排查手册**：从「新手常见错误」到「启动界面 / 代码界面」再到「其他」，写清了每个 config.plist 选项该填什么、每个 Quirk 是干什么的。适合系统性地过一遍。 |
| [CSDN · 相关详细教程](https://blog.csdn.net/gitblog_00456/article/details/155172793) | 第三方博客上的详细教程（收录时站点返回 521 打不开，链接照原样保留，稍后再试）。 |

> 三份都是**外部资料**，内容与版权归原作者所有，本仓库只收录链接、不转载正文。

---

<a name="sec10"></a>
## 十、用到的软件与驱动（官网）

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

<a name="sec11"></a>
## 十一、目录说明

| 路径 | 内容 |
|---|---|
| `README.md` | 本文档（安装教程） |
| `安装Windows+其他多系统.txt` | 我最初的原始笔记（未整理版） |
| `EFI/` | 调通的 OpenCore EFI（可直接对比参考） |
| `USB定制/` | USB 端口数据（`usb.json`）与 `USBMap.kext` |
| `session-log/` | 原始对话日志含唯一标识，**已于 2026-10-28 移除** |

---

<a name="sec12"></a>
## 十二、macOS 26（Tahoe）迁移记录

> 这一节是**升级到 macOS 26 之后**的排障记录。
> **上面的 `EFI/` 是 macOS 15 的**，到 macOS 26 有几处必须重做。

### 12.1 USB 全部失效 —— 属性名改了

Tahoe 把 USB 端口的属性名从 **`UsbConnector` / `port`** 改成了 **`usb-port-type` / `usb-port-number`**。

**做法**：在 `USBMap.kext` 的每个端口里**同时保留旧键、新增新键**，并加 `kUSBMuxEnabled = true`。
我这台 12 个端口这样改完，USB 恢复。

### 12.2 无线（Intel AX210）—— 换 Tahoe 构建

原来的 `AirportItlwm 2.4.0` 是 **Sequoia 构建**，Tahoe 加载不了。

**做法**：换成 Tahoe 构建 **`AirportItlwm-Tahoe-v2.4.0-RELEASE-alpha`**（`tahoe-vtd-1`），
并在 `boot-args` 里加 **`itlwm_he=1`**。

- 项目地址：<https://github.com/laobamac/itlwm>

### 12.3 音频（Realtek ALC256）—— AppleHDA 被移除了

**macOS 26 移除了 `AppleHDA.kext`**，所以 AppleALC 没有后端可用。

**做法**：装 **`SimpleHDA-Tahoe-v1.0.0-RELEASE`**，在 `Kernel → Add` 里排在 `AppleALC` **之后**，
`MinKernel = 25.0.0` / `MaxKernel = 25.99.99`。

- 项目地址：<https://github.com/laobamac/SimpleHDA>

### 12.4 OpenCore 从 DEBUG 换回 RELEASE（不再跑码）

- 从 `boot-args` 移除 **`-v`**
- OpenCore **1.0.9 DEBUG → 1.0.9 RELEASE**（Dortania 构建）
- 替换 `OpenCore.efi`、`BOOTx64.efi` 及 `OpenRuntime / OpenCanopy / ResetNvramEntry / OpenLinuxBoot`
- `Misc → Debug → Target = 0`、`DisplayLevel = 0`、`AppleDebug = false`

### 12.5 OC 里的 Ubuntu 引导项 —— 相对路径不行

自定义 Ubuntu 项用相对路径会报 `OCB: LoadImage failed - Not Found`。

**做法**：改成**完整 UEFI 设备路径**：

```
PciRoot(0x1)/Pci(0x1D,0x0)/Pci(0x0,0x0)/NVMe(0x1,XX-XX-XX-XX-XX-XX-XX-XX)/HD(4,GPT,XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX,0xDB8AD800,0x219800)/\EFI\ubuntu\shimx64.efi
```

两个坑：

- `PciRoot` 是 **`0x1`**，不是常见的 `0x0`
- NVMe 的 EUI64 在 UEFI 里写作 `XX-XX-XX-XX-XX-XX-XX-XX`，
  和 Linux `sysfs` 里的 `XX-XX-XX-XX-XX-XX-XX-XX` **正好反序**

### 12.6 睡眠「睡死」—— 已解决

2026-10-28 定位到两个实际问题：`sleepimage` 只有 1 GB（内存 32 GB），且 `/var/vm` 没有指向 VM 卷。修复：

- `sudo pmset -a hibernatemode 0 standby 0 autopoweroff 0 powernap 0`
- 备份并重建 `/private/var/vm -> /System/Volumes/VM`
- `DisableRtcChecksum=true` 已开启

结果：睡眠/唤醒正常。详见 [13.3 睡眠](#sleep)。

### 12.7 触控板（ELAN 04F3:32E2，I2C-HID）—— **已解决**

2026-10-28 已解决。根因和完整补丁见 [13.1 触控板](#touchpad)。

- `LegionI2CArrowLake.kext` 的 `IOClass` 从 `VoodooI2CPCILakeController` 改成 `VoodooI2CPCIController`
- VoodooI2C 打补丁：先判断 `-vi2c-force-polling`，再判断 APIC
- VoodooI2CHID 打补丁：`Interrupt Mode=Polling` 时强制使用 200 ms 定时器
- 备份和补丁版路径见 13.1 / 13.11

### 12.8 macOS 26 下的关键配置

| 项 | 值 |
|---|---|
| OpenCore | **1.0.9 RELEASE**（Dortania build-repo，`OpenCorePkg-78d5ff8`）|
| SMBIOS | `MacBookPro16,1` |
| `csr-active-config` | `0A43`（SIP 关闭）|
| `SecureBootModel` | `Disabled` |
| `DisableIoMapper` | `true` |
| `DisableRtcChecksum` | `true` |
| `ACPI → Delete` | `DMAR`，`All=true`、`Enabled=true` |
| `Kernel → Add` | `AsusSMC.kext`（1.4.1，测试 Fn/背光）|
| `Misc → Boot → Timeout` | `5` |
| `Misc → Debug → Target` | `67`（AppleDebug/ApplePanic=true）|
| `Misc → Entries` | Ubuntu 项 **已禁用/占位**，请换成你自己的分区路径 |
| `Kernel → Add` 末尾 | `SimpleHDA.kext`（25.0.0–25.99.99）|
| 已禁用 | `itlwm` · `UTBDefault` · `SMCSuperIO` |

**`boot-args`（macOS 26 当前）**：

```
-vi2c-force-polling nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4 -gux_defer_usb2 alcid=13 itlwm_he=1 keepsyms=1 -ibtcompatbeta revpatch=sbvmm,cpuname
```

> 注意：**没有 `-v`**（不再跑码），**没有 `-wegnoegpu`**（不能禁 N 卡）。

### 12.9 驱动版本（macOS 26）

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
| AirportItlwm | 2.4.0（Tahoe 构建）|
| itlwm | 2.3.0（禁用）|
| IntelBluetoothFirmware / IntelBTPatcher | 2.5.0 |
| BlueToolFixup | 2.7.3 |
| VoodooI2C | 2.9.1（已打 force-polling 补丁）|
| VoodooI2CHID | 1（已打 Polling 定时器补丁）|
| AsusSMC | 1.4.1（键盘背光不支持）|
| VoodooPS2Controller | 2.3.8 |
| USBMap / USBToolBox | 1.1（已改 Tahoe 键）/ 1.2.0 |
| LegionI2CArrowLake | 1.1.0（IOClass 改为 `VoodooI2CPCIController`）|

### 12.10 相关素材

| 路径 | 内容 |
|---|---|
| `macos26/README.md` | 这次迁移的**完整原始报告** |
| `macos26/evidence/` | 取证材料 13 份：`lspci` · `lsblk` · `efibootmgr` · `kexts` · `config-diff` · `mont` … |
| `macos26/scripts/` | `fix-sleep-pmset.sh` · `diagnose-sleep.sh` · `find-voodooi2c.sh` |
| `macos26/config.plist` | macOS 26 下的当前配置（供对照）|
| `macos26/session/` | 原始会话日志含真实序列号/MLB/UUID，**已于 2026-10-28 移除**；仅保留脱敏摘要 |
| `session-log/` | 含唯一标识的原始会话归档，**已于 2026-10-28 移除** |
| `docs/maclator-usage.md` | maclator 使用教程（本机部署验证后已清理）|

> ⚠️ **升级前务必保留 macOS 15 版本的 EFI**（就是仓库里的 `EFI/`），
> 否则万一 macOS 26 起不来，没有回滚的路。

---

<a name="maintenance"></a>
## 十三、安装后的维护与修复（2026-10-28）

这一节是**系统安装完成后的维护与修复记录**（2026-10-28）；安装指南在本文前面的章节，触控板放在本节最前面。

### 本次实测环境

| 项目 | 值 |
|---|---|
| 机型 | ASUS FX608LP（天选 6 Pro） |
| CPU | Intel Core Ultra 9 275HX（Arrow Lake-HX，24 核） |
| 独显 | NVIDIA GeForce RTX 5070 Laptop（GB206，`10DE:2D58`，8 GB） |
| 核显 | Intel Arrow Lake iGPU `8086:7D67`（macOS 无驱动，未使用） |
| 内存 | 32 GB |
| 屏幕 | 2560×1600 165 Hz（内屏接 NVIDIA） |
| 系统 | macOS 26.7.1（25G241） |
| NVIDIA 驱动 | 1401 / nullmoth NVRM 2.6.2（Metal 3） |
| SMBIOS | `MacBookPro16,1` |
| EFI 分区 | `disk1s4`（1.1 GB FAT32；编号可能随启动顺序变化） |
| csr-active-config | `0x0A43` |
| SecureBootModel | `Disabled` |

---

<a name="touchpad"></a>
### 13.1 触控板（重点，已解决）

#### 硬件与症状

- 触控板：ELAN `04F3:32E2`
- ACPI 设备：`TPD0`，名称 `ASCE1200`，`compatible=PNP0C50`
- I2C 控制器：`I2C2`，PCI ID `8086:7f4e`（Arrow Lake-HX LPSS）
- 触控板 I2C 地址：`0x15`
- 症状：系统设置里有触控板选项，`hidutil` 也能看到虚拟 `Magic Trackpad 2`，但**指针不动、点击无反应**；静态画面正常。

#### 根因 1：VoodooI2C 优先走 APIC，忽略了 `-vi2c-force-polling`

VoodooI2C 2.9.1 的 `VoodooI2CDeviceNub::getDeviceResources()` 逻辑是：

```cpp
// 只要 APIC pin <= 0x2f，就直接返回，后面的 force_polling 根本不会执行
if (validateAPICInterrupt() == kIOReturnSuccess)
    return kIOReturnSuccess;
```

本机 `TPD0` 的 `IOInterruptSpecifiers` 是 `<2c00000003000000>`，pin `0x2c <= 0x2f`，所以被当成“有效 APIC”。但这个 APIC 中断实际不送数据，`-vi2c-force-polling` 被完全忽略，控制器一直是 `Interrupt Mode = APIC`。

#### 根因 2：自定义 `LegionI2CArrowLake.kext` 用了不存在的类

`LegionI2CArrowLake.kext` 是仅含 `Info.plist` 的注入项，匹配 `0x7f4c8086&0xFFFCFFFF`（覆盖 `7f4e`），但原配置写的是：

```text
IOClass = VoodooI2CPCILakeController
```

而 stock VoodooI2C 2.9.1 里**没有这个类**，所以控制器根本不会绑定。

修复：

```text
IOClass = VoodooI2CPCIController
IOPCIMatch = 0x7f4c8086&0xFFFCFFFF
```

#### 根因 3：VoodooI2CHID 在 Polling 模式下仍然创建了不会触发的事件源

控制器绑定后，`VoodooI2CDeviceNub` 变成 `Interrupt Mode = Polling`，但 `VoodooI2CHIDDevice::handleStart()` 只要 `IOInterruptEventSource::interruptEventSource(...)` 返回非空，就会使用它；这个事件源在 Polling 模式下永远不触发，所以 `getInputReport()` 从来没被调用，200 ms 定时器也没启用。

修复：读取 DeviceNub 的 `Interrupt Mode` 属性，若是 `Polling` 就拒绝创建事件源，强制走定时器：

```cpp
bool polling_mode = false;
if (OSString* interrupt_mode = OSDynamicCast(OSString, api->getProperty("Interrupt Mode")))
    polling_mode = interrupt_mode->isEqualTo("Polling");

if (!polling_mode)
    interrupt_source = IOInterruptEventSource::interruptEventSource(
        this,
        OSMemberFunctionCast(IOInterruptEventAction, this, &VoodooI2CHIDDevice::interruptOccured),
        api, 0);

if (interrupt_source) {
    work_loop->addEventSource(interrupt_source);
} else {
    interrupt_simulator = IOTimerEventSource::timerEventSource(
        this,
        OSMemberFunctionCast(IOTimerEventSource::Action, this, &VoodooI2CHIDDevice::simulateInterrupt));
    work_loop->addEventSource(interrupt_simulator);
}
```

同时把 VoodooI2C 的 `force_polling` 判断提前到 `validateAPICInterrupt()` 之前：

```cpp
IOPCIDevice *pci_device = controller->nub->controller->physical_device.pci_device;

bool force_polling = checkKernelArg("-vi2c-force-polling");
force_polling = force_polling ||
    (pci_device != nullptr && pci_device->getProperty("force-polling") != nullptr);

if (force_polling) {
    IOLog("%s::%s Forced polling mode, skipping APIC and GPIO interrupts\n",
          getName(), acpi_device->getName());
    return kIOReturnSuccess;
}

// 之后再检查 APIC
if (validateAPICInterrupt() == kIOReturnSuccess)
    return kIOReturnSuccess;
```

#### 编译与安装

- 需要：Xcode Command Line Tools、`MacKernelSDK`、`VoodooGPIO` 源码、`VoodooInput` 头文件（在 `VoodooInput.kext/Contents/Resources/VoodooInputMultitouch/`）
- 构建：

```bash
xcodebuild -project VoodooI2C.xcodeproj -scheme VoodooI2C \
  -configuration Release -derivedDataPath /tmp/vi2c_build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build

xcodebuild -project VoodooI2CHID.xcodeproj -scheme VoodooI2CHID \
  -configuration Release -derivedDataPath /tmp/vi2chid_build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build
```

- 替换 EFI 里：

```text
EFI/OC/Kexts/VoodooI2C.kext
EFI/OC/Kexts/VoodooI2CHID.kext
```

- boot-args 保留：

```text
-vi2c-force-polling
```

#### 验证

```bash
ioreg -c VoodooI2CDeviceNub -r -l | grep -iE 'name|Interrupt Mode|gpio|apic'
ioreg -c VoodooI2CHIDDevice -r -l | grep -iE 'name|HIDRM|ReportInterval'
hidutil list | grep -iE 'Trackpad|I2C'
```

修复后 `ASCE1200` 显示：

```text
"Interrupt Mode" = "Polling"
```

并且 `VoodooI2CPrecisionTouchpadHIDEventDriver`、`VoodooInput`、`AppleMultitouchTrackpadHIDEventDriver`、`AppleMultitouchDevice` 全部存在，指针和点击正常工作。

#### 备份与注意

- EFI 里的原版备份：

```text
EFI/OC/Kexts/VoodooI2C.kext.bak-forcedpolling-*
EFI/OC/Kexts/VoodooI2CHID.kext.bak-hidpolling-*
```

- 本机备份目录里保留了补丁版副本：`~/Documents/ASUS-FX608LP-Hackintosh-backup/patched-voodooi2c/`
- **以后升级 VoodooI2C / VoodooI2CHID，或用别的 EFI 覆盖，这两个补丁会丢失，触控板会再次失效。** 把补丁版覆盖回 `EFI/OC/Kexts` 即可。
- 该方案依赖 `-vi2c-force-polling`；如果 boot-args 被清掉，需要补回。

---

<a name="efi-checks"></a>
### 13.2 1401 EFI 检查 4 项

1401 的 “Check my EFI” 只读不写，它报的 4 项对应以下修改（都在 `EFI/OC/config.plist`）：

| 1401 报错 | 改哪里 | 改成 |
|---|---|---|
| Intel Bluetooth needs one boot setting on macOS 26 | NVRAM → Add → `7C436110-AB2A-4BBB-A880-FE41995C9F82` → `boot-args` | 追加 `-ibtcompatbeta` |
| macOS 26 updates can stop at the prohibited sign | 同上 `boot-args` | 追加 `revpatch=sbvmm` |
| Core Ultra PCs freeze before macOS starts with VT-d on | ACPI → Delete | 新增 `DMAR`，`All=true`、`Enabled=true` |
| A failed start leaves no log | Misc → Debug | `Target=67`、`AppleDebug=true`、`ApplePanic=true` |

当前 `boot-args`：

```text
-vi2c-force-polling nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth
amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4
-gux_defer_usb2 alcid=13 itlwm_he=1 keepsyms=1
-ibtcompatbeta revpatch=sbvmm,cpuname
```

说明：

- `-ibtcompatbeta` 是 Intel 蓝牙在 macOS 26 上的加载开关。
- `revpatch=sbvmm` 让 RestrictEvents 骗过机型检查，OTA 更新不会停在 prohibited 标志。
- 删除 `DMAR` 只是让 macOS 看不到 VT-d，Windows/Linux 不受影响；BIOS 里能直接关 VT-d 也可以代替。
- `Kernel → Quirks → DisableIoMapper` 已经是 `true`。
- 修改前备份 `config.plist`；改完用 OCAT/ocvalidate 校验。

---

<a name="sleep"></a>
### 13.3 睡眠 / 休眠（已解决）

本机 32 GB 内存，但原来的 `sleepimage` 只有 **1.0 GB**；而且 `/var/vm` 是一个普通目录，落在 Data 卷上，没有指向 VM 卷。`hibernatemode 3` 下休眠镜像根本写不下，容易出现 `Sleep Wake failure in EFI` / 睡死。

修复：

```bash
# 关闭 hibernation / standby / powernap
sudo pmset -a hibernatemode 0 standby 0 autopoweroff 0 powernap 0

# 把 /var/vm 恢复成指向 VM 卷（先备份）
sudo mv /private/var/vm /private/var/vm.bak-20261027-221922
sudo ln -s /System/Volumes/VM /private/var/vm
```

验证：

```bash
pmset -g | grep -E 'hibernatemode|standby|powernap'
df -h /var/vm     # 应显示 /dev/disk2s6（VM 卷）
```

另外 `Kernel → Quirks → DisableRtcChecksum` 已经是 `true`。修复后睡眠/唤醒正常。

> 网上一些“黑苹果睡眠终极指南”会推荐 `HibernationFixup` / `OS-X-EAPD-Codec-Commander`；这类文章很多是 AI 生成的通用内容，不一定适用于本机。本机实际有效的是 `hibernatemode 0` + 修好 `/var/vm` + `DisableRtcChecksum`。如果以后要恢复休眠模式 3/25，再考虑 `HibernationFixup`。

---

<a name="keyboard"></a>
### 13.4 键盘、Fn、AsusSMC、键盘背光、Fn+F10

#### Windows 键盘习惯

默认映射：`Win = Command`、`Alt = Option`、`Ctrl = Control`。Windows 快捷键大多把 Ctrl 换成 Command：

| 操作 | Windows | macOS |
|---|---|---|
| 复制/粘贴/剪切 | Ctrl+C/V/X | Cmd+C/V/X |
| 撤销/重做 | Ctrl+Z / Ctrl+Y | Cmd+Z / Cmd+Shift+Z |
| 全选/保存/查找/打印 | Ctrl+A/S/F/P | Cmd+A/S/F/P |
| 关闭窗口/退出程序 | Alt+F4 | Cmd+W / Cmd+Q |
| 切换程序/窗口 | Alt+Tab | Cmd+Tab / Cmd+` |
| 锁屏 | Win+L | Ctrl+Cmd+Q |
| 截图 | Win+Shift+S | Cmd+Shift+4 / Cmd+Shift+3 |
| 重命名 | F2 | Enter |
| 删除文件 | Delete | Cmd+Delete |
| 行首/行尾 | Home/End | Cmd+←/→ 或 Fn+←/→ |
| 文档首/尾 | Ctrl+Home/End | Cmd+↑/↓ |
| 上/下页 | PgUp/PgDn | Fn+↑/↓ |
| 任务管理器 | Ctrl+Shift+Esc | Cmd+Space 搜“活动监视器” |

方案：

- 系统自带：系统设置 → 键盘 → 键盘快捷键 → 修饰键，把 Caps Lock 改成 Control/Escape。
- 让 Ctrl+C 等于 Cmd+C：Karabiner-Elements 的 complex modification，注意给 Terminal/iTerm 加例外。
- Home/End：macOS 原生是 Fn+方向键；或 `~/Library/KeyBindings/DefaultKeyBinding.dict` 映射。

#### AsusSMC 与键盘背光

- 已加载 `AsusSMC 1.4.1`，匹配 `ATKD`/`PNP0C14`。
- 它报 `IsKeyboardBacklightSupported = No`，所以**键盘背光调不了**；这是这版 AsusSMC 没识别 2025 款背光接口，不是设置问题。
- `IsTouchpadEnabled = Yes` 属性存在，但 Fn+F10 没有把事件送进 AsusSMC；Fn+F9 在 macOS 下变成了打印/F9。
- AsusSMC 源码里触控板切换绑的是 `0x6B`（注释写 Fn+F9），2025 款的 Fn 层没有走这条 ATK 事件；因此简单改按键映射也不会生效，需要先抓到真实的 PS/2 scan code/ATK code，属于后续项目。

如果只是想“用鼠标时别误触触控板”，可以用系统自带设置：

```bash
defaults write com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad -bool true
```

或在系统设置 → 辅助功能 → 指针控制 → 触控板选项 → 勾“有鼠标或无线触控板时忽略内置触控板”。这个设置只在外接鼠标存在时生效，可能需要注销一次；恢复设为 `false`。

---

<a name="fan"></a>
### 13.5 风扇与功耗

本机内屏 `MNG007DA5-3`（2560×1600 165 Hz）接在 RTX 5070 上，Intel iGPU 显示 “No Kext Loaded”。macOS 下没有 Windows 的 Optimus/核显桌面模式，**dGPU 一直在驱动内屏**，待机功耗和发热基线就比 Windows 高，风扇更容易起来。

可做的：

1. 系统设置 → 显示器，把刷新率从 165 Hz 降到 120 Hz 或 60 Hz。
2. 接电源时开低电量模式：`sudo pmset -c lowpowermode 1`；关 Power Nap/网络唤醒：`sudo pmset -a powernap 0 womp 0`。
3. 回 Windows 的 Armoury Crate，把风扇/性能模式设为 **Silent** 或 **Balanced**；ASUS EC 档位通常会保留到下次启动。
4. 想看真实功耗：`sudo powermetrics --samplers cpu_power,gpu_power -i 1000 -n 3`。
5. AsusSMC 目前不支持这台 2025 款的背光/风扇控制，不能指望它调风扇曲线。

预期：即使优化完，macOS 下的待机噪音也很难完全追上 Windows，因为 dGPU 直连内屏这个前提改不了。

---

<a name="scaling"></a>
### 13.6 显示缩放 / HiDPI

显示器实际暴露的模式（用 CoreGraphics 列出）：

- 1x：2560×1600、2048×1280、1600×1200、1600×1000、1344×1008、1344×840、1280×960、1280×800、1024×768、1024×640、800×600、800×500、640×480
- 2x/HiDPI：只有 1280×800（backbuffer 2560×1600）、1024×640（2048×1280）、800×600、800×500

所以：

- 选 2560×1600 = 1x，16 英寸 2.5K 约 188 PPI，macOS UI 按 ~110 PPI 设计，图标特别小是正常的。
- 选 1280×800 = 2x，等效约 94 PPI，所以大小合适，但空间浪费。
- 没有 1600×1000 HiDPI（需要 3200×2000 backbuffer）、1707×1067 HiDPI、1920×1200 HiDPI；驱动把 framebuffer 上限卡在 2560×1600，macOS 不会生成更大的 scaled 模式。

解决方案：

1. **BetterDisplay**（推荐）：Custom Resolution 3200×2000（1600×1000 HiDPI）或 3414×2134（1707×1067 HiDPI）；如果物理模式被拒绝，用 Virtual Screen 建 3200×2000 虚拟屏再 Mirror 到内屏。
2. **SwitchResX**：同样可以加 custom resolution + HiDPI，付费。
3. 免费临时档：Option 点“Scaled”选 2048×1280 或 1600×1000（1x），图标变大但会发虚。
4. EDID override：显示 ID 是 vendor `0x0E77` / product `0x1656`，但驱动可能忽略，优先级放后。
5. 给 1401 提 feature request，要求暴露 3200×2000 等 scaled 模式。

---

<a name="render"></a>
### 13.7 网页滚动破碎 / 渲染异常

准确描述：不是花屏/闪烁，而是**滚动网页时出现像拼图被打乱的块**；静止正常。更像 WindowServer/NVAccel 的 **scan-out / 部分更新** 路径问题，不是 DSC 高刷新闪烁。

1401 驱动自己的文档说：

> `-nvrmnoflip` keeps NVAccel on the copy path (no zero-copy scan-out of the composited surface) and is **the first thing to try when the desktop flashes or tears while the cursor moves**.

所以首选测试是给 boot-args 加 `-nvrmnoflip`（**本次尚未加入**，因为需要重启验证）。其他测试：

- 刷新率降到 120/60 Hz。
- `sudo sysctl debug.nvrmfb_flip_latch=2`（运行时，可改回 1）。
- 用 1401 的 “Record the flicker” 在滚动时录 20 秒，然后 Send logs。
- 如果只有浏览器有问题：先试 Firefox 软件渲染（`gfx.webrender.software=true`），再对比 Safari。
- 当前驱动 2.6.2 已是最新；这个问题还没有最终解决。

---

<a name="maclator"></a>
### 13.8 maclator 部署与使用

maclator 是“反向 Rosetta”：在 Intel Mac 上运行 arm64 macOS 应用。本次已在本机完成部署验证，随后按用户要求清理了安装文件；完整教程见仓库 [`docs/maclator-usage.md`](docs/maclator-usage.md)。

> 原项目仓库：<https://github.com/linuxkid473/maclator>（maclator 是 linuxkid473 的项目；本仓库只记录部署/使用，不包含其源码。）

本机验证结果：

| 项目 | 结果 |
|---|---|
| Rust | 1.99.1 |
| ipsw | 3.1.739 |
| maclator | `~/bin/maclator`（x86_64） |
| GPU bridge | `~/bin/gpu/libmclbridge.dylib`、`libmclmetal.dylib` |
| sysroot | `~/maclator-sysroot/...`，约 5.4 GB |
| JIT 自检 | `ok=6229 mismatch=0` |
| CPU | arm64 hello 输出 `hello from arm64` |
| GPU | `--gpu` 创建 Metal 设备：`NVIDIA GeForce RTX 5070 Laptop GPU (NVMTL over NVK GB206-B)` |

注意：

- 真实 Chromium/VS Code/Electron 仍可能因为 1401 的 Metal 覆盖不完整而崩溃或花屏；先不带 `--gpu` 验证应用，再试 GPU。
- maclator 只支持 arm64；x86_64 应用本来就能原生跑。
- 不支持音频、多数 IOKit 硬件、沙盒应用、Swift 很重的应用、`CAMetalLayer` 应用。
- 第一次启动大应用很慢，正常退出才会保存 AOT 缓存；强杀不保存。

---

<a name="menubar"></a>
### 13.9 菜单栏图标间距

天选 6 Pro 没有刘海，但菜单栏图标间距可以调小/调大：

```bash
# 当前设为 5（4 是平衡，0 最紧）
defaults -currentHost write -globalDomain NSStatusItemSpacing -int 5
defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 5
```

需要注销/重新登录生效。恢复默认：

```bash
defaults -currentHost delete -globalDomain NSStatusItemSpacing
defaults -currentHost delete -globalDomain NSStatusItemSelectionPadding
```

这组键只影响菜单栏 status item 的间距，不影响 Dock/刘海；图标特别多时仍可能被挤掉。

---

<a name="status"></a>
### 13.10 当前状态：已解决 / 未解决

| 问题 | 状态 |
|---|---|
| 触控板（ELAN 04F3:32E2 / 8086:7f4e） | ✅ 已解决（补丁版 VoodooI2C + VoodooI2CHID） |
| 1401 EFI 检查 4 项 | ✅ 已改，1401 检查应无问题 |
| 睡眠睡死 | ✅ 已解决（hibernatemode 0 + /var/vm + DisableRtcChecksum） |
| 静音 | ✅ 正常 |
| 菜单栏间距 | ✅ 已设为 5 |
| maclator 部署 | ✅ 已验证 CPU/GPU，随后按用户要求清理 |
| 键盘背光 | ❌ AsusSMC 报 `IsKeyboardBacklightSupported=No` |
| Fn+F10 触控板开关 | ❌ 2025 Fn 层没进 AsusSMC；未解决 |
| 网页滚动破碎 | ❌ 未解决；首选试 `-nvrmnoflip` |
| 1600×1000 / 1707×1067 HiDPI | ❌ 驱动不暴露；用 BetterDisplay |
| 风扇比 Windows 吵 | ⚠️ 结构性原因（dGPU 直连内屏），只能降低刷新率/功耗 |

---

<a name="backup"></a>
### 13.11 备份、恢复与 SMBIOS

- 修改 EFI 前的完整备份：本机 `~/Documents/ASUS-FX608LP-Hackintosh-backup/EFI-backups/EFI-backup-20261027-221905.zip`
- 触控板补丁原版备份：

```text
EFI/OC/Kexts/VoodooI2C.kext.bak-forcedpolling-*
EFI/OC/Kexts/VoodooI2CHID.kext.bak-hidpolling-*
```

- 触控板补丁版副本：`~/Documents/ASUS-FX608LP-Hackintosh-backup/patched-voodooi2c/`
- 恢复说明：`~/Documents/ASUS-FX608LP-Hackintosh-backup/EFI恢复说明.txt`
- SMBIOS：仓库当前文件已使用占位符；**请用 OCAT / GenSMBIOS 生成你自己的 `SystemSerialNumber`、`MLB`、`SystemUUID`、`ROM`**，不要直接开机使用占位符。
- 2026-10-28 已对当前文件和 git 历史做脱敏，并移除含真实序列号/MLB/UUID 的原始压缩会话日志；如果你在 fork、缓存或旧 commit 里看到旧值，请以最新 `main` 为准。
- Git 托管方可能仍缓存旧对象；如果对隐私要求高，建议在 GitHub 支持页面请求清理缓存，或重新建一个干净的仓库。

---

---

<a name="sec14"></a>
## 十四、声明与致谢

### 本仓库由 `deepseek-flash` 上传

**内容由作者实操、AI 辅助完成。**

| 环节 | 执行者 |
|---|---|
| 教程原文、EFI 配置、驱动调通、BIOS 设置、实机验证 | **作者本人**（**AI 辅助**：排查报错、改配置、看截图） |
| 仓库归档、README 整理与补充、FAQ 筛选、外部链接核实与标注、上传 | **`deepseek-flash`**（DeepSeek Harness 智能体） |
| 2026-10-28 维护：触控板补丁、1401 EFI 检查、睡眠/显示/渲染排查、README 更新 | **ZCode / deepseek-flash** |
| macOS 下的 NVIDIA 驱动 | **nullmoth / 1401**（转载，非本仓库产物） |

> 说明：整个安装过程由作者在真机上完成，**全程有 AI 辅助**（排查、配置、文档）；
> 本仓库的归档、清理、链接核对与 README 整理由 AI 完成。

### 外部引用链接

以下内容均来自外部，**版权归各自作者所有，本仓库只收录链接、不转载正文**：

| 类别 | 来源 | 用途 |
|---|---|---|
| 排查手册 | [黑苹果屋 · OC 各种卡速查表](https://imacos.top/2021/01/19/0154/) | 按报错原文查解决方案 |
| 排查手册 | [黑苹果星球 · OpenCore 卡住拯救手册 Q&A](https://heipg.cn/tutorial/opencore-install-errors-handbook.html) | 系统性排查 |
| 排查手册 | [CSDN · 详细教程](https://blog.csdn.net/gitblog_00456/article/details/155172793) | 第三方博客（收录时站点返回 521） |
| 显卡驱动 | [nullmoth/nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver) · [nullmoth/1401](https://github.com/nullmoth/1401) | macOS 下的 NVIDIA 驱动 |
| 引导器与工具 | [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) · [OCAT](https://github.com/ic005k/OCAuxiliaryTools) · [RapidEFI](https://github.com/JeoJay127/RapidEFI-Tool) · [USBToolBox](https://github.com/USBToolBox/tool) | OpenCore 生态 |
| 系统与工具 | [Ubuntu](https://ubuntu.com/download/desktop) · [balenaEtcher](https://etcher.balena.io/) · [DiskGenius](https://www.diskgenius.com/) · [EasyUEFI](https://www.easyuefi.com/) | 安装介质 / 分区 / 引导项 |
| Kext 源码 | [Acidanthera](https://github.com/acidanthera) · [OpenIntelWireless](https://github.com/OpenIntelWireless) · [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) · [Mieze/RTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X) · [USBToolBox/kext](https://github.com/USBToolBox/kext) · [CpuTopologyRebuild](https://github.com/b00t0x/CpuTopologyRebuild) | 内核驱动 |
| 触控板 | [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) · [VoodooI2CHID](https://github.com/VoodooI2C/VoodooI2CHID) · [VoodooI2C 文档](https://voodooi2c.github.io/) · [OMEN Arrow Lake EFI](https://github.com/Coolzhy/EFI-OMEN16-am2xxx-public) | 触控板补丁参考 |
| ASUS 键盘/背光 | [AsusSMC](https://github.com/hieplpvip/AsusSMC) | Fn/背光/EC 参考 |
| NVIDIA 驱动 | [1401 troubleshooting](https://github.com/nullmoth/nvidia-macos-driver/blob/main/docs/TROUBLESHOOTING.md) · [CHANGELOG](https://github.com/nullmoth/nvidia-macos-driver/blob/main/CHANGELOG.md) | 1401 行为/限制 |
| 显示缩放 | [BetterDisplay](https://github.com/waydabber/BetterDisplay) · [SwitchResX](https://www.madrau.com/) | HiDPI 缩放 |
| 菜单栏 | [sinlov：菜单栏间距](https://blog.sinlov.cn/posts/2025/12/11/macos-adjusts-the-spacing-between-icons-in-the-system-menu-bar/) | defaults 方法 |
| 睡眠 | [OC-Little-Translated 休眠](https://github.com/5T33Z0/OC-Little-Translated/tree/main/Content/04_Fixing_Sleep_and_Wake_Issues/Changing_Hibernation_Modes) · [CSDN 睡眠文章](https://blog.csdn.net/gitblog_00866/article/details/160169991) | 休眠/睡死参考（CSDN 为 AI 生成，仅参考） |
| maclator | [linuxkid473/maclator](https://github.com/linuxkid473/maclator) · [ipsw](https://github.com/blacktop/ipsw) | Intel 跑 arm64 |
| 触控板命令 | [Apple StackExchange: Disabling trackpad from CLI](https://apple.stackexchange.com/questions/125324/disabling-the-trackpad-from-the-command-line) | USBMouseStopsTrackpad 参考 |
| SMBIOS 工具 | [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) · [OCAT](https://github.com/ic005k/OCAuxiliaryTools) | 生成序列号/MLB/UUID/ROM |
| 触控板构建依赖 | [MacKernelSDK](https://github.com/acidanthera/MacKernelSDK) · [VoodooGPIO](https://github.com/VoodooI2C/VoodooGPIO) · [VoodooInput](https://github.com/acidanthera/VoodooInput) | 编译补丁 kext |
| 参考资料 | [Dortania OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/) | 黑苹果权威教程 |

**如果以上任何链接的内容侵犯了你的权益，请在 Issues 中提出，我会立即移除。**

### 版权小结

- 系统、软件、驱动、kext 的版权均归**各自作者**所有
- 本仓库**不含** macOS 安装镜像，也不含 Apple 的任何受版权保护文件
- `EFI/`、`USB定制/` 与教程文字为作者整理，可自由参考，**但请自行承担使用风险**

---

## 最后再说一次

1. **显卡驱动是 nullmoth / 1401 的，我只是转载记录**，版权归原作者
2. **EFI 只适配 ASUS FX608LP 这一台机器**
3. **SMBIOS 序列号请自己生成**，不要照抄
4. 黑苹果有风险，**先备份**
5. macOS 是 Apple 的版权软件，本仓库不含任何系统文件

祝你好运 🍀
