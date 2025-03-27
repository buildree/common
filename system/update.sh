#!/bin/sh

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

    # リポジトリファイルのバックアップ
    mkdir -p /root/repo_backup
    cp /etc/yum.repos.d/* /root/repo_backup/

    # 日本のミラーサイト（理化学研究所）
    RIKEN_MIRROR="https://ftp.riken.jp/Linux"

    # OSごとのリポジトリ設定
    case $OS in
        "rocky")
            # BaseOSリポジトリの設定
            dnf config-manager --disable '*'
            dnf config-manager --enable baseos
            dnf config-manager --enable appstream
            dnf config-manager --setopt=baseos.baseurl=$RIKEN_MIRROR/rocky/\$releasever/BaseOS/\$basearch/os/ --save
            dnf config-manager --setopt=appstream.baseurl=$RIKEN_MIRROR/rocky/\$releasever/AppStream/\$basearch/os/ --save
            ;;
        "almalinux")
            # BaseOSリポジトリの設定
            dnf config-manager --disable '*'
            dnf config-manager --enable baseos
            dnf config-manager --enable appstream
            dnf config-manager --setopt=baseos.baseurl=$RIKEN_MIRROR/almalinux/\$releasever/BaseOS/\$basearch/os/ --save
            dnf config-manager --setopt=appstream.baseurl=$RIKEN_MIRROR/almalinux/\$releasever/AppStream/\$basearch/os/ --save
            ;;
        *)
            echo "このOSのミラーサイト設定は未対応です: $OS"
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