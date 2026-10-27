# maclator 使用教程（本次部署验证后已清理）

> 适用机器：Intel Core Ultra 9 275HX / macOS 26.7.1 / RTX 5070 Laptop（1401 驱动）
> 说明：本机曾完成部署验证（CPU/GPU），随后按用户要求清理了安装文件；按本文步骤可以重新安装。
> maclator 是**在 Intel Mac 上运行 arm64 macOS 应用**的实验性反向 Rosetta，不是虚拟机，也不是日常可用的 Rosetta 替代品。

---

## 1. 它是什么，能做什么

maclator 把 **arm64（Apple Silicon）macOS 应用**加载到 Intel 机器上执行：

- AArch64 解释器 + x86-64 JIT
- arm64e dyld shared cache（从 Apple IPSW 提取，约 5.4 GB）
- 可选 Metal bridge：把 guest 的 Metal 调用转到宿主 GPU

**能跑（官方验证过）：**

- arm64 CLI 工具（fastfetch、neovim 等）
- 简单 AppKit 应用
- VS Code darwin-arm64（Electron）
- Chromium arm64（含 GPU 加速）
- balenaEtcher arm64（界面能起，写盘未验证）

**不能跑 / 不完整：**

- 音频
- 多数 IOKit 硬件访问
- 沙盒应用
- Swift 很重的 Apple 应用
- `CAMetalLayer` 类应用
- arm64e-only 或 FairPlay 加密的 App Store / iOS-on-Mac 应用
- x86_64 应用（这些本来就能原生运行，不需要 maclator）

---

## 2. 本次部署时的安装位置（已清理）

| 内容 | 路径 |
|---|---|
| maclator 主程序 | `~/bin/maclator` |
| GPU bridge | `~/bin/gpu/libmclbridge.dylib`、`~/bin/gpu/libmclmetal.dylib` |
| arm64 系统缓存 | `~/maclator-sysroot/maclator-sysroot.4Cp452__Mac14,2`（约 5.4 GB） |
| AOT 翻译缓存 | `~/Library/Caches/Maclator/aot/` |
| 源码 / 构建目录 | `~/Desktop/maclator-download/maclator-main` |
| PATH 配置 | `~/.zshrc` 里的 `export PATH="$HOME/bin:$PATH"` |

新开一个 Terminal，或者：

```bash
source ~/.zshrc
which maclator
```

---

## 3. 5 分钟快速验证

```bash
source ~/.zshrc

# 1) JIT 自检，期望 mismatch=0
maclator --selftest-jit dpreg 20000

# 2) 编译一个最小 arm64 程序并运行
cat > hello.c <<'EOF'
#include <stdio.h>
int main(void) { puts("hello from arm64"); return 0; }
EOF
clang -arch arm64 hello.c -o hello
codesign -f -s - hello
maclator ./hello
```

本次部署时已经验证通过：

```text
jit selftest [dpreg]: ok=6229 mismatch=0
hello from arm64
```

---

## 4. 基本用法

```bash
maclator [options] ./arm64-binary [args...]
```

例子：

```bash
maclator ./fastfetch
maclator ./hello arg1 arg2
maclator "/path/Some.app/Contents/MacOS/Some"
```

注意事项：

- 目标必须是 **arm64 Mach-O**。先确认：

  ```bash
  file ./App
  lipo -archs ./App
  ```

  应该看到 `arm64`；如果是 `arm64e` only 或 `x86_64`，maclator 不适用。
- 如果应用抱怨签名，先复制一份再 ad-hoc 重签：

  ```bash
  cp App App.maclator
  codesign -f -s - App.maclator
  maclator ./App.maclator
  ```

- GUI 应用没有 LaunchServices 启动；直接运行 `.app/Contents/MacOS/` 里的可执行文件。部分 AppKit 应用可用，`CAMetalLayer` 应用通常不行。
- 第一次启动大应用会很慢，因为代码是边跑边翻译；**正常退出**（Cmd+Q 或应用自己的 Quit）才会保存 AOT 缓存。强杀不保存。

---

## 5. 常用参数

| 参数 | 作用 |
|---|---|
| `--interp` | 只用解释器，关闭 JIT/AOT；很慢，用来排除 JIT bug |
| `--no-aot` | 不读取也不写入 AOT 翻译缓存 |
| `--aot <程序>` | 预先翻译并退出，不运行程序 |
| `--gpu` | 把 guest 的 Metal 调用转到宿主 GPU |
| `--gpu-only SUBSTR` | 只给参数里包含 SUBSTR 的 guest 进程加载 GPU bridge，例如 `--type=gpu-process` |
| `--sysroot DIR` | 指定 arm64e dyld shared cache 目录 |
| `--dyld PATH` | 指定 guest dyld，默认 `/usr/lib/dyld` |
| `--trace` | 打印 syscall / Mach message / 路径重定向（日志很大） |
| `--dump-on-fault` | 崩溃时把寄存器 + 反汇编写到 `/tmp/maclator-fault-<pid>.log` |

环境变量：

| 变量 | 作用 |
|---|---|
| `MACLATOR_SYSROOT` | 指定 sysroot 目录 |
| `MACLATOR_DYLD` | 指定 guest dyld |
| `MACLATOR_GPU_DIR` | 指定 GPU bridge 的 dylib 目录 |
| `MACLATOR_CACHE` | 指定 AOT 缓存目录 |
| `MCL_STATS=1` | 输出 GPU bridge 统计/诊断 |
| `MCL_NOFAST=1` / `MCL_OLDDESC=1` / `MCL_NOBATCH=1` | GPU 渲染异常时用来二分排查 |
| `MCL_TRACE=1` | GPU bridge 消息跟踪 |

如果找不到 sysroot：

```bash
export MACLATOR_SYSROOT="$HOME/maclator-sysroot/maclator-sysroot.4Cp452__Mac14,2"
```

---

## 6. 跑 Chromium（arm64 + GPU）

先下载 arm64 Chromium 快照（官方开发时用的是 1706829 / Chromium 157，其他版本可能也能跑）：

```bash
mkdir -p ~/Downloads/chromium-arm64
cd ~/Downloads/chromium-arm64
curl -L -o chrome-mac.zip \
  https://commondatastorage.googleapis.com/chromium-browser-snapshots/Mac_Arm/1706829/chrome-mac.zip
unzip -q chrome-mac.zip
```

然后用安装脚本装好的启动器：

```bash
chromium-gpu https://example.com
```

它等价于：

```bash
maclator --gpu --gpu-only --type=gpu-process ./Chromium \
  --no-sandbox --disable-gpu-sandbox --disable-gpu-watchdog \
  --use-angle=metal --use-gl=angle --enable-gpu --ignore-gpu-blocklist \
  --renderer-process-limit=1 --disable-extensions --disable-sync \
  --disable-background-networking --disable-component-update \
  --disable-features=Translate,OptimizationHints,MediaRouter,AutofillServerCommunication,SpareRendererForSitePerProcess,GlobalMediaControls \
  --user-data-dir="$HOME/chromium-data" --no-first-run --no-default-browser-check \
  --remote-debugging-port=9333
```

如果 Chromium 不在默认目录：

```bash
CHROMIUM_DIR="/path/Chromium.app/Contents/MacOS" chromium-gpu
```

检查 GPU：打开 `chrome://gpu`，应看到 ANGLE/Metal 硬件加速；或者访问 `http://127.0.0.1:9333/json/version`。

不想用 GPU：

```bash
cd ~/Downloads/chromium-arm64/chrome-mac/Chromium.app/Contents/MacOS
maclator ./Chromium --no-sandbox --disable-gpu --user-data-dir=/tmp/chromium-data
```

---

## 7. 跑 VS Code（darwin-arm64）

下载并解压到 `~/vscode-arm64`：

```bash
mkdir -p ~/vscode-arm64
cd ~/vscode-arm64
curl -L -o vscode.zip https://update.code.visualstudio.com/latest/darwin-arm64/stable
unzip -q vscode.zip
```

启动：

```bash
code
# 等价于 vscode-gpu
```

软件渲染版本：

```bash
cd ~/vscode-arm64
maclator "./Visual Studio Code.app/Contents/MacOS/Code" \
  --no-sandbox --disable-gpu \
  --user-data-dir="$HOME/vscode-data" --disable-workspace-trust
```

说明：

- 集成终端可能提示 “unable to resolve shell environment”，只影响终端环境变量，不影响编辑器。
- 如果遇到 V8 JIT 稳定性问题，加 `--js-flags=--jitless`。
- 路径不在默认位置时用 `VSCODE_DIR` / `VSCODE_DATA` 覆盖。

---

## 8. 跑 balenaEtcher（arm64）

把 arm64 版 `balenaEtcher.app` 放到 `/Applications`，然后：

```bash
etcher
```

它使用 GPU bridge + `--no-sandbox`。如果直接 `maclator ./balenaEtcher` 会报 “GPU … usable. Goodbye”，要么用 `etcher` 启动器，要么加 `--disable-gpu`。

> 写盘（raw disk access）尚未验证，重要 U 盘请先备份。

---

## 9. 任意 Electron / Chromium 应用

```bash
maclator --gpu --gpu-only --type=gpu-process ./App \
  --no-sandbox --disable-gpu-sandbox --disable-gpu-watchdog \
  --use-angle=metal --use-gl=angle --enable-gpu --ignore-gpu-blocklist
```

要点：

- Electron/Chromium 必须加 `--no-sandbox`（Chromium 沙盒在 maclator 下起不来）。
- 只让 GPU 进程加载 bridge：`--gpu-only --type=gpu-process`；不要给所有 helper 进程都加载，否则渲染进程会被拖慢。
- 第一次着色器编译可能触发 Chromium watchdog，所以有 `--disable-gpu-watchdog`。

---

## 10. GPU：本机 1401 驱动的特别注意

本机已验证：

```bash
maclator --gpu /tmp/metalinfo
```

可以创建 Metal 设备：

```text
Metal device: NVIDIA GeForce RTX 5070 Laptop GPU
             (NVMTL over NVK GB206-B)
```

但这只说明 **Metal 设备能创建**，不代表所有 Metal 特性都完整。1401/NVRM 是实验性驱动，真实应用（Chromium/VS Code/Electron）仍可能：

- GPU 进程崩溃
- 花屏 / 颜色不对
- 性能很低
- 直接回退到软件渲染

建议顺序：

1. 先不带 `--gpu` 启动，确认应用本身能工作。
2. 再带 `--gpu` 对比。
3. 如果 GPU 进程崩了，Chromium 会自动回退软件渲染；也可以显式加 `--disable-gpu`。
4. 渲染异常时试：

   ```bash
   MCL_NOFAST=1 maclator --gpu ...
   MCL_OLDDESC=1 maclator --gpu ...
   MCL_NOBATCH=1 maclator --gpu ...
   ```

5. 需要诊断时加 `MCL_STATS=1`、`MCL_TRACE=1`。

如果找不到 GPU bridge：

```bash
export MACLATOR_GPU_DIR="$HOME/bin/gpu"
```

---

## 11. 性能与 AOT 缓存

- **第一次启动大应用很慢**：代码边跑边翻译。
- **正常退出**才会写入 `~/Library/Caches/Maclator/aot/`；强杀/崩溃不会保存。
- 第二次启动会快很多；如果又变慢，通常是上次被强杀，或者 maclator 版本变了导致缓存失效。
- 可以预翻译：

  ```bash
  maclator --aot ./App
  ```

- 不想用缓存：

  ```bash
  maclator --no-aot ./App
  ```

- 怀疑 JIT bug：

  ```bash
  maclator --interp ./App
  maclator --selftest-jit blocks 200000
  ```

- Chromium/VS Code 会起约 10 个进程；本机 32 GB 内存比官方测试机宽裕，但仍建议用 `chromium-gpu` 的 lean flags。

---

## 12. 已知限制

- 音频不支持。
- 多数 IOKit 硬件访问不支持。
- 沙盒应用不支持。
- Swift 很重的 Apple 应用不支持。
- `CAMetalLayer` 类应用不支持。
- arm64e-only / FairPlay 加密应用不支持。
- 不支持 x86_64（本来就原生跑）。
- maclator 版本更新如果改变代码生成，会清空 AOT 缓存。

---

## 13. 排错

| 现象 | 处理 |
|---|---|
| `maclator: command not found` | `source ~/.zshrc`，或直接用 `~/bin/maclator` |
| 启动时报 `dyld_shared_cache_arm64e` 找不到 | 设置 `MACLATOR_SYSROOT`，或 `--sysroot DIR` |
| `sandbox initialization failed` | Electron/Chromium 加 `--no-sandbox` |
| “GPU … usable. Goodbye” / `gpu_data_manager_impl_private.cc` | 用 GPU 启动器，或加 `--disable-gpu` |
| `cannot load GPU bridge` | 设置 `MACLATOR_GPU_DIR="$HOME/bin/gpu"`，或重跑 `scripts/install.sh` |
| Chromium 开了 GPU 只有 ~1 fps | 窗口不可见会节流；加 `--disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-background-timer-throttling`，并检查 GPU 进程是否崩了 |
| 第一次慢、第二次快 | 正常；正常退出以保存 AOT 缓存 |
| 第二次又慢 | 上次被强杀/崩溃，或缓存被新版本失效 |
| 崩溃在 `str wzr, [xzr]` 等 | `--dump-on-fault`，看 `/tmp/maclator-fault-<pid>.log` |
| 进程 0% CPU 卡住 | `kill -USR1 <pid>` 打线程栈；偶尔是多线程 GPU 进程 fork 的罕见 hang，重启应用 |
| 想确认是不是 JIT 问题 | `maclator --interp ./App` 对比；再跑 `--selftest-jit` |
| `--gpu` 颜色/渲染不对 | 依次试 `MCL_NOFAST=1`、`MCL_OLDDESC=1`、`MCL_NOBATCH=1`；`MCL_TRACE=1` 看消息 |
| 签名弹窗 | 不要给翻译缓存加可执行权限；guest 二进制 ad-hoc 重签 `codesign -f -s - file` |

---

## 14. 卸载 / 清理

```bash
rm -f ~/bin/maclator
rm -rf ~/bin/gpu
rm -f ~/bin/chromium ~/bin/code ~/bin/etcher ~/bin/chromium-gpu ~/bin/vscode-gpu ~/bin/etcher-gpu
rm -rf ~/maclator-sysroot
rm -rf ~/Library/Caches/Maclator
rm -rf ~/Desktop/maclator-download
```

如果不再需要，把 `~/.zshrc` 里的：

```bash
export PATH="$HOME/bin:$PATH"
```

删掉或注释。Chromium/VS Code 的 `~/chromium-data`、`~/vscode-data` 也可一并删除。

---

## 15. 安全与合规

- maclator 本身不包含 Apple 二进制；arm64 userland/dyld cache 是你用 `ipsw` 从 Apple 服务器下载的，需自行遵守 Apple 许可。
- 不要用它跑 FairPlay/DRM 加密内容；项目明确不支持，也不尝试绕过。
- 这是实验项目，随时可能崩；重要工作不要只放在 maclator 里跑。
- 本机 GPU 路径依赖 1401/NVRM 实验驱动；驱动更新后先确认系统正常，再测 maclator。

---

## 16. 本机验证记录

| 项目 | 结果 |
|---|---|
| Rust | 1.99.1 |
| ipsw | 3.1.739 |
| maclator | `~/bin/maclator`，x86_64 |
| sysroot | `~/maclator-sysroot/maclator-sysroot.4Cp452__Mac14,2`，约 5.4 GB |
| JIT 自检 | `ok=6229 mismatch=0` |
| CPU | arm64 hello 输出 `hello from arm64` |
| GPU | `--gpu` 创建设备 `NVIDIA GeForce RTX 5070 Laptop GPU (NVMTL over NVK GB206-B)` |

真实 Chromium/VS Code/Etcher 尚未在本机跑过；按上面的步骤先用不带 `--gpu` 的方式验证，再开 GPU。

---

## 参考

- 仓库：<https://github.com/linuxkid473/maclator>
- 命令行/应用用法：`docs/USAGE.md`
- 安装/编译：`docs/SETUP.md`
- GPU bridge：`docs/GPU.md`
- 排错：`docs/TROUBLESHOOTING.md`
- 本地副本：`~/Desktop/maclator-download/maclator-main/docs/`
