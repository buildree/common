#!/bin/sh

<<COMMENT

ミラーサイトの変更とアップデートの実行

COMMENT

# メッセージ表示関数
start_message(){
echo ""
echo "======================開始: $1 ======================"
echo ""
}

end_message(){
echo ""
echo "======================完了: $1 ======================"
echo ""
}

# 日本のミラーサイトを設定
set_japanese_mirrors() {
    # OSを検出
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif [ -f /etc/redhat-release ]; then
        if grep -q "CentOS Stream" /etc/redhat-release; then
            OS="centos-stream"
        elif grep -q "AlmaLinux" /etc/redhat-release; then
            OS="almalinux"
        elif grep -q "Rocky" /etc/redhat-release; then
            OS="rocky"
        elif grep -q "Oracle" /etc/redhat-release; then
            OS="ol"
        else
            OS="rhel"
        fi
    else
        echo "サポートされていないディストリビューションです"
        return 1
    fi

    # 日本のミラーサイト（理化学研究所）
    RIKEN_MIRROR="https://ftp.riken.jp/Linux"

    # OSごとにミラーサイトを設定
    case $OS in
        "rocky")
            sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/Rocky-*.repo
            sed -i "s|^#baseurl=http://dl.rockylinux.org|baseurl=$RIKEN_MIRROR/rocky|g" /etc/yum.repos.d/Rocky-*.repo
            ;;
        "almalinux")
            sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/almalinux*.repo
            sed -i "s|^#baseurl=https://repo.almalinux.org|baseurl=$RIKEN_MIRROR/almalinux|g" /etc/yum.repos.d/almalinux*.repo
            ;;
        "centos-stream")
            sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/centos*.repo
            sed -i "s|^#baseurl=http://vault.centos.org|baseurl=$RIKEN_MIRROR/centos|g" /etc/yum.repos.d/centos*.repo
            ;;
        "ol")
            sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/ol*.repo
            sed -i "s|^#baseurl=https://yum.oracle.com|baseurl=$RIKEN_MIRROR/oracle|g" /etc/yum.repos.d/ol*.repo
            ;;
        "rhel")
            sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/rhel*.repo
            sed -i "s|^#baseurl=https://repo.rhel.com|baseurl=$RIKEN_MIRROR/rhel|g" /etc/yum.repos.d/rhel*.repo
            ;;
        *)
            echo "このOSには対応していません: $OS"
            return 1
            ;;
    esac

    # キャッシュをクリアし、メタデータを再生成
    dnf clean all
    dnf makecache
}

# システムアップデート
start_message "ミラーサイトの変更"
set_japanese_mirrors
end_message "ミラーサイトの変更"

start_message "システムアップデート"
dnf -y update
dnf -y autoremove
dnf clean all
end_message "システムアップデート"