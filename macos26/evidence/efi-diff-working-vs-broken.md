# 能启动 EFI vs 之前卡死 EFI

- 能启动：`macos26/EFI/`（01:35 基线 + 仓库补丁版 VoodooI2C/CHID + Legion 基类 + AsusSMC）
- 之前卡死：本机 `EFI-CURRENT-20261028-175950`（未上传）

## 结论

两次的 **VoodooI2C、VoodooI2CHID、LegionI2CArrowLake 二进制完全相同**（SHA256 前缀分别一致）。差异集中在 CPU 配置、AsusSMC 开关和 `VoodooI2CServices` 插件：

| 项 | 之前卡死 | 现在能启动 |
|---|---|---|
| `ProcessorType` | 3841 | 3841 |
| `boot-args` | 含 `-ibtcompatbeta revpatch=sbvmm,cpuname` | 不含 `cpuname`/`revpatch` |
| `ProvideCurrentCpuInfo` | true | false |
| `AppleXcpmForceBoost` | false | true |
| `AsusSMC` | 禁用 | 启用 |
| `VoodooI2CServices.kext` | **缺失**（配置仍引用） | **存在** |
| `VoodooI2C`/`CHID`/`Legion` 二进制 | 相同 | 相同 |

## 说明

- 之前卡死在 **OC FileVault 密码之后**；CPU 名称/调度那组 `cpuname` + `ProvideCurrentCpuInfo` 的改动是主要风险点，现已回退为 01:35 可用配置。
- 旧 EFI 的 `VoodooI2C.kext` 缺少 `VoodooI2CServices`，但配置仍加载该插件；新 EFI 用仓库完整补丁版补齐。
- 触控板真正生效依赖：`LegionI2CArrowLake` 的 `IOClass=VoodooI2CPCIController`、VoodooI2C force-polling 补丁、VoodooI2CHID Polling 定时器补丁、`-vi2c-force-polling`。
- AsusSMC 与触控板无关；仓库说明里键盘背光仍不支持。
