#!/bin/bash

# 创建目录（如果不存在）
mkdir -p /root/keys/

# 安装expect工具（如果未安装）
if ! command -v expect &> /dev/null; then
    echo "安装expect工具..."
    apt-get update
    apt-get install -y expect
fi

# 安装Rust和Cargo（如果未安装）
if ! command -v cargo &> /dev/null; then
    echo "安装Rust和Cargo..."
    apt-get update
    apt-get install -y curl build-essential pkg-config libssl-dev
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo "Rust和Cargo安装完成"
fi

# 检查soundnessup是否已安装，如果没有则安装
SOUNDNESSUP_PATH="$HOME/.soundness/bin/soundnessup"
SOUNDNESS_CLI_PATH="$HOME/.soundness/bin/soundness-cli"

if [ ! -f "$SOUNDNESSUP_PATH" ]; then
    echo "安装Soundness CLI..."
    # 安装soundnessup
    curl -sSL https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/install | bash
    
    # 直接导出PATH而不依赖source命令
    export PATH="$HOME/.soundness/bin:$PATH"
fi

# 立即添加到当前PATH中
export PATH="$HOME/.soundness/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# 检查soundnessup是否可用
if [ ! -f "$SOUNDNESSUP_PATH" ] && ! command -v soundnessup &> /dev/null; then
    echo "错误: 无法找到或运行soundnessup命令。"
    echo "请尝试手动执行以下命令后再次运行此脚本:"
    echo "source ~/.bashrc"
    echo "或者:"
    echo "export PATH=\$HOME/.soundness/bin:\$PATH"
    exit 1
fi

# 安装Soundness CLI
echo "安装Soundness CLI工具..."
"$SOUNDNESSUP_PATH" install

# 确认soundness-cli是否可用
if [ ! -f "$SOUNDNESS_CLI_PATH" ] && ! command -v soundness-cli &> /dev/null; then
    echo "错误: 无法找到或运行soundness-cli命令。"
    echo "请确保已安装soundnessup并执行了'soundnessup install'命令。"
    echo "您可以尝试手动执行以下命令:"
    echo "export PATH=\$HOME/.soundness/bin:\$PATH"
    echo "$SOUNDNESSUP_PATH install"
    exit 1
fi

# 创建expect脚本文件
cat > /tmp/generate_key.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 10
set keyname [lindex $argv 1]
spawn [lindex $argv 0] generate-key --name $keyname
expect "Enter password for secret key:"
send "\r"
expect "Confirm password:"
send "\r"
expect -re {Public key: (.*)\n}
set public_key $expect_out(1,string)
puts $public_key
expect eof
EOF

cat > /tmp/export_key.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 10
set keyname [lindex $argv 1]
spawn [lindex $argv 0] export-key --name $keyname
expect "Enter password to decrypt the secret key:"
send "\r"
expect -re {Mnemonic for key pair '.*?':(.*?)WARNING}
set mnemonic $expect_out(1,string)
puts $mnemonic
expect eof
EOF

cat > /tmp/delete_key.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 10
set keyname [lindex $argv 1]
spawn [lindex $argv 0] delete-key --name $keyname
expect "Are you sure you want to delete the key pair*"
send "y\r"
expect eof
EOF

chmod +x /tmp/generate_key.exp
chmod +x /tmp/export_key.exp
chmod +x /tmp/delete_key.exp

# 询问用户生成次数
read -p "请输入要生成的密钥对数量（默认为50）: " input_count
# 如果用户输入为空，使用默认值50
COUNT=${input_count:-50}

echo "将生成 $COUNT 对密钥..."
echo "----------------------------------------"

# 先清理所有可能存在的旧密钥
"$SOUNDNESS_CLI_PATH" list-keys 2>/dev/null | grep -o "my-key-[0-9]*" | while read keyname; do
    echo "删除已存在的密钥: $keyname"
    /tmp/delete_key.exp "$SOUNDNESS_CLI_PATH" "$keyname" >/dev/null 2>&1 || true
done

# 循环执行
for ((i=1; i<=COUNT; i++)); do
    echo "第 $i 次执行..."
    
    # 为每个密钥指定唯一名称
    KEY_NAME="my-key-$i"

    # 1. 清除该密钥（如果已存在）
    /tmp/delete_key.exp "$SOUNDNESS_CLI_PATH" "$KEY_NAME" >/dev/null 2>&1 || true
    
    # 短暂延迟，确保前一个进程完全结束
    sleep 1

    # 2. 生成新密钥
    echo "步骤1: 生成密钥对..."
    public_key=$(/tmp/generate_key.exp "$SOUNDNESS_CLI_PATH" "$KEY_NAME" | tr -d '\n\r ')

    # 3. 导出助记词
    echo "步骤2: 导出助记词..."
    mnemonic=$(/tmp/export_key.exp "$SOUNDNESS_CLI_PATH" "$KEY_NAME" | sed 's/[[:space:]]*$//')

    # 4. 保存结果到文件（格式：公钥----助记词）
    echo "${public_key}----${mnemonic}" >> /root/keys/saved_keys.txt

    # 5. 显示结果
    echo "第 $i 次完成！"
    echo "密钥名称: $KEY_NAME"
    echo "保存格式: ${public_key}----${mnemonic}"
    echo "----------------------------------------"
    
    # 添加延迟，防止进程冲突
    sleep 1
done

echo "全部 $COUNT 次执行完成！"
echo "生成的密钥对已保存到 /root/keys/saved_keys.txt"
