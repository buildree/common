#!/bin/sh

<<COMMENT
URL：https://buildree.com/

目的：
・EPELリポジトリのインストール
・Apache+PHP インストール時のみ remi リポジトリの追加
・ディストリビューション毎にGPGキーを変更

COMMENT

echo ""

start_message(){
echo ""
echo "======================開始======================"
echo ""
}

end_message(){
echo ""
echo "======================完了======================"
echo ""
}

# EPELリポジトリのインストール
start_message
echo "EPELリポジトリをインストールしています..."

# 対応するGPGキーのURLを設定
case $DIST_ID in
    "almalinux")
        GPG_KEY="https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux"
        ;;
    "rocky")
        GPG_KEY="https://download.rockylinux.org/pub/rocky/RPM-GPG-KEY-Rocky-$DIST_VERSION_ID"
        ;;
    "centos-stream" | "centos")
        GPG_KEY="https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official"
        ;;
    "rhel" | "redhat")
        GPG_KEY="https://www.redhat.com/security/data/fd431d51.txt"
        ;;
    "ol")
        GPG_KEY="https://yum.oracle.com/RPM-GPG-KEY-oracle-ol$DIST_VERSION_ID"
        ;;
    *)
        echo "警告: 認識されないディストリビューションですが、処理を続行します"
        GPG_KEY="https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux"
        ;;
esac

# Keyの更新
rpm --import $GPG_KEY
dnf remove -y epel-release
dnf -y install epel-release
end_message

# 実行中のスクリプト名をチェック
SCRIPT_NAME=$(basename "$0")

# Apache+PHPインストールスクリプトの場合にのみremiリポジトリをインストール
if [ "$SCRIPT_NAME" = "apache_php.sh" ]; then
    start_message
    echo "Apache+PHP環境のための remi リポジトリをインストールしています..."
    
    # OSバージョンに基づいてremiリポジトリをインストール
    if [ "$DIST_MAJOR_VERSION" = "8" ]; then
        dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    elif [ "$DIST_MAJOR_VERSION" = "9" ]; then
        dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
    else
        echo "警告: サポートされていないOSバージョンです: $DIST_MAJOR_VERSION"
    fi
    
    # remiリポジトリのGPGキーをインポート
    rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi
    echo "remiリポジトリのインストールが完了しました。"
    end_message
else
    echo "Apache+PHP環境インストールではないため、remiリポジトリはインストールされません。"
fi