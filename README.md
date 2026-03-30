# antigravity-login-fix

一个面向 Windows 的第三方修复脚本仓库，用来给 `Antigravity 1.2x` 注入最小 `BigInt` 登录兼容补丁。  
仓库只包含 **检测、备份、注入、回滚** 脚本，不包含任何官方源文件或二进制。

## 适用范围

- 系统：Windows
- 脚本：PowerShell 优先，同时附带 `.cmd` 包装入口
- 支持版本：`Antigravity 1.2x`
- 默认目标：`Antigravity.exe` 安装目录下的 `resources\app\out\main.js`

> 说明：脚本采用“版本检测 + 文件特征匹配 + 不匹配即退出”的保守策略。  
> 即使版本号满足 `1.2x`，只要目标 `main.js` 结构不符合预期，也不会写入。

## 仓库内容

- `install.ps1` / `install.cmd`
  - 检测本机安装
  - 检测版本与文件特征
  - 创建备份
  - 注入 `BigInt.prototype.toJSON` 登录兜底
- `check.ps1` / `check.cmd`
  - 只读检查当前状态
- `restore.ps1` / `restore.cmd`
  - 从备份恢复 `main.js`
- `lib/AntigravityLoginFix.Common.ps1`
  - 共用检测与文件写入逻辑
- `tests/Test-AntigravityLoginFix.ps1`
  - 本地夹具测试脚本

## 快速使用

### 1. 检查当前状态

```powershell
powershell -ExecutionPolicy Bypass -File .\check.ps1
```

或直接双击：

```text
check.cmd
```

### 2. 安装登录补丁

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

或直接双击：

```text
install.cmd
```

### 3. 回滚到备份版本

```powershell
powershell -ExecutionPolicy Bypass -File .\restore.ps1
```

或直接双击：

```text
restore.cmd
```

## 可选参数

所有 PowerShell 脚本都支持以下参数：

- `-TargetPath`
  - 手动指定 `Antigravity` 安装目录，或直接指定 `Antigravity.exe`
- `-BackupDir`
  - 自定义备份目录
- `-Force`
  - 跳过交互确认（仅 `install.ps1` / `restore.ps1`）

示例：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -TargetPath "C:\Users\YourName\AppData\Local\Programs\Antigravity" -Force
```

## 备份与回滚

- 默认备份文件名固定为：

```text
main.js.antigravity-login-fix.backup.js
```

- 如果未指定 `-BackupDir`，备份会写在目标 `main.js` 同目录
- 如果脚本检测到备份已存在且内容与当前文件不一致，会直接退出，避免覆盖未知备份

## 风险说明

- 这是第三方修复脚本，不代表官方项目
- 脚本会修改你本机安装目录中的 `main.js`
- 仓库不会分发任何官方源文件或二进制
- 脚本只做最小登录修复，不包含导出补丁、UI 补丁、自动更新屏蔽等额外修改
- 如果未来官方彻底修复了登录链路，这个仓库可能就不再需要

## 常见失败原因

- `未找到 Antigravity 安装目录`
  - 请用 `-TargetPath` 手动指定
- `当前版本不在支持范围内`
  - 当前脚本只支持 `1.2x`
- `main.js 文件结构与预期不符`
  - 目标文件不是预期版本或已经被其他工具重写
- `备份文件已存在且内容不一致`
  - 说明当前目录里已有旧备份，建议先检查后再决定是否继续

## 本地验证

仓库附带一个夹具测试脚本，会复制本机 `Antigravity.exe` 到临时目录，并对临时 `main.js` 完成：

- 检查
- 安装
- 重复安装幂等测试
- 回滚恢复

运行方式：

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Test-AntigravityLoginFix.ps1
```

## 许可

本仓库采用 [MIT License](./LICENSE)。
