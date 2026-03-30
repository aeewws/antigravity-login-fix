# antigravity-login-fix

这是一个给 **Google Antigravity** 用的 Windows 小工具。

它解决的是这样一种情况：

- 同一台电脑上
- 有的 Google 账号能正常登录 Antigravity
- 有的 Google 账号明明授权成功了，却还是登不上去
- 或者反复登录很多次才能进去

这个仓库的作用，就是给本机的 Antigravity 打一个 **最小登录修复补丁**，让这类账号登录问题更容易恢复正常。

> 这不是官方项目。  
> 这是第三方修复脚本，只改你自己电脑上的 Antigravity 安装文件，不会上传你的账号信息。

## 这个仓库适合谁

适合下面这种情况：

- 你在 Windows 上用 Antigravity
- 你遇到过“有的谷歌账号能登，有的不能登”
- 你想要一个 **下载后双击就能用** 的修复工具

## 能做什么

- 检查你电脑上的 Antigravity 当前状态
- 自动给登录问题打补丁
- 自动备份原文件
- 需要时一键恢复原文件

## 一键双击使用（推荐）

如果别人是从 GitHub 下载 ZIP 到桌面，解压后直接双击下面任意一个文件即可：

- `OneClickInstall.cmd`
  - 直接安装登录修复
- `OneClickCheck.cmd`
  - 检查当前状态
- `OneClickRestore.cmd`
  - 把修改恢复回去

这些入口会自动调用 PowerShell 脚本，并保留窗口，方便看结果。

## 命令行用法

### 1. 检查当前状态

```powershell
powershell -ExecutionPolicy Bypass -File .\check.ps1
```

### 2. 安装登录修复

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### 3. 恢复原文件

```powershell
powershell -ExecutionPolicy Bypass -File .\restore.ps1
```

## 目前支持

- 系统：Windows
- Antigravity 版本：`1.2x`

脚本会先检查版本和目标文件结构。  
如果不是支持的版本，或者目标文件和预期不一致，就会直接退出，不会乱改。

## 备份与安全

- 修改前会先备份原文件
- 如果发现备份异常，会直接停止
- 如果已经打过同类补丁，不会重复乱写
- 如果需要，可以随时回滚

默认备份文件名：

```text
main.js.antigravity-login-fix.backup.js
```

## 常见情况

### 1. 明明授权成功了，还是登不上去

这正是这个仓库主要想解决的问题。

### 2. 同一台电脑，不同账号表现不一样

这也是常见现象。  
有些账号能直接登录，有些账号会卡住、循环、或者要试很多次。

### 3. 会不会影响我的账号安全

不会上传你的账号信息。  
这个仓库只是在你自己电脑上修改本地 Antigravity 的一个文件，并且会先备份。

### 4. 会不会把软件改坏

脚本是保守策略：

- 先检查
- 再备份
- 再写入
- 最后复检

而且你可以随时恢复。

## 常见失败原因

- `未找到 Antigravity 安装目录`
  - 可以手动指定路径
- `当前版本不在支持范围内`
  - 当前脚本只支持 `1.2x`
- `目标文件结构与预期不符`
  - 说明这个版本或安装状态和当前脚本不匹配
- `备份文件已存在且内容不一致`
  - 说明当前目录里已有旧备份，建议先检查

## 可选参数

- `-TargetPath`
  - 手动指定 Antigravity 安装目录，或直接指定 `Antigravity.exe`
- `-BackupDir`
  - 自定义备份目录
- `-Force`
  - 跳过确认（仅安装/恢复脚本）

示例：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetPath "C:\Users\YourName\AppData\Local\Programs\Antigravity" -Force
```

## 本地验证

仓库附带一个测试脚本，会在临时目录里复制一份假安装环境，然后验证：

- 检查
- 安装
- 重复安装不乱写
- 恢复
- 异常情况直接失败

运行方式：

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Test-AntigravityLoginFix.ps1
```

## 打包发布 ZIP

仓库内置发布打包脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\build-release.ps1
```

执行后会生成：

- `dist/antigravity-login-fix-v<version>.zip`
- `dist/antigravity-login-fix-v<version>.zip.sha256`

## 许可

本仓库采用 [MIT License](./LICENSE)。
