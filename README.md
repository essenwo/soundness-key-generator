# Soundness Key Generator

一个用于自动安装 Soundness CLI 并生成多个密钥对的一体化脚本。

## 一键安装与使用

你可以通过以下命令一键下载并运行此脚本：

```bash
# 使用curl下载脚本
curl -O https://raw.githubusercontent.com/essenwo/soundness-key-generator/main/all_in_one.sh

# 或者使用wget下载脚本
wget https://raw.githubusercontent.com/essenwo/soundness-key-generator/main/all_in_one.sh

# 赋予脚本执行权限
chmod +x all_in_one.sh

# 运行脚本
./all_in_one.sh
```

## 功能特点

- 自动安装 Rust 和 Cargo 环境
- 自动安装 Soundness CLI
- 自动安装 expect 工具
- 支持批量生成密钥对
- 每个密钥对生成唯一的名称，避免冲突
- 自动保存所有密钥对信息到 `/root/keys/saved_keys.txt`

## 适用环境

- Linux 系统（已在Ubuntu和Debian上测试）
- 需要 root 权限

## 密钥存储位置

所有生成的密钥将保存在 `/root/keys/` 目录下，包括：
- 生成的密钥对
- 包含所有密钥和助记词的存档文件

## 安全提示

本脚本生成的密钥对默认不设密码保护。在生产环境中使用前，建议考虑添加密码保护。
