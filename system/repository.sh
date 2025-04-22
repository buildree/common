#!/bin/sh

<<COMMENT
URL：https://buildree.com/

目的：
・EPELリポジトリのインストール
・Apache+PHP インストール時のみ remi リポジトリの追加
・MySQL環境の対応（8.4および9）
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

# ディストリビューション情報を取得
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DIST_ID=$ID
    DIST_VERSION_ID=$VERSION_ID
    DIST_MAJOR_VERSION=$(echo $VERSION_ID | cut -d. -f1)
else
    echo "警告: /etc/os-release が見つかりません。デフォルト値を使用します。"
    DIST_ID="unknown"
    DIST_VERSION_ID="0"
    DIST_MAJOR_VERSION="0"
fi

# 実行中のスクリプト名から環境情報を取得
SCRIPT_NAME=$(basename "$0")
INSTALL_APACHE_PHP=false
INSTALL_MYSQL=false
MYSQL_VERSION=""

# スクリプト名から環境設定を検出
if [[ "$SCRIPT_NAME" == *"apache_php"* ]]; then
    INSTALL_APACHE_PHP=true
    
    # Apache+PHPに加えて、MySQLの設定もチェック
    if [[ "$SCRIPT_NAME" == *"mysql84"* ]]; then
        INSTALL_MYSQL=true
        MYSQL_VERSION="84"
    elif [[ "$SCRIPT_NAME" == *"mysql90"* ]]; then
        INSTALL_MYSQL=true
        MYSQL_VERSION="90"
    fi
fi

echo "検出された設定:"
echo "ディストリビューション: $DIST_ID $DIST_VERSION_ID (メジャーバージョン: $DIST_MAJOR_VERSION)"
echo "Apache+PHP: $INSTALL_APACHE_PHP"
echo "MySQL: $INSTALL_MYSQL (バージョン: $MYSQL_VERSION)"
echo ""

# EPELリポジトリのインストール - すべての場合に実行
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

# Apache+PHPインストールの場合にのみremiリポジトリをインストール
if [ "$INSTALL_APACHE_PHP" = true ]; then
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

# MySQL環境のリポジトリ設定
if [ "$INSTALL_MYSQL" = true ]; then
    start_message
    echo "MySQL $MYSQL_VERSION 環境のためのリポジトリを設定しています..."
    
    if [ "$MYSQL_VERSION" = "84" ]; then
        # MySQL 8.4用のリポジトリ設定
        if [ "$DIST_MAJOR_VERSION" = "8" ]; then
            rpm -ivh https://dev.mysql.com/get/mysql84-community-release-el8-1.noarch.rpm
            dnf config-manager --disable mysql84-community
            dnf config-manager --enable mysql84-community
        elif [ "$DIST_MAJOR_VERSION" = "9" ]; then
            rpm -ivh https://dev.mysql.com/get/mysql84-community-release-el9-4.noarch.rpm
            dnf config-manager --disable mysql84-community
            dnf config-manager --enable mysql84-community
        else
            echo "警告: サポートされていないOSバージョンです: $DIST_MAJOR_VERSION"
        fi
        
        # MySQL 8.4リポジトリのGPGキーをインポート
        rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
        echo "MySQL 8.4リポジトリの設定が完了しました。"
    elif [ "$MYSQL_VERSION" = "90" ]; then
        # MySQL 9用のリポジトリ設定
        if [ "$DIST_MAJOR_VERSION" = "8" ]; then
            rpm -ivh https://dev.mysql.com/get/mysql84-community-release-el8-1.noarch.rpm
            dnf config-manager --disable mysql80-community
            dnf config-manager --enable mysql90-community
        elif [ "$DIST_MAJOR_VERSION" = "9" ]; then
            rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm
            dnf config-manager --disable mysql80-community
            dnf config-manager --enable mysql90-community
        else
            echo "警告: サポートされていないOSバージョンです: $DIST_MAJOR_VERSION"
        fi
        
        # MySQL 9リポジトリのGPGキーをインポート
        rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
        echo "MySQL 9リポジトリの設定が完了しました。"
        echo "注意: MySQL 9がまだ公式にリリースされていない場合、このリポジトリは機能しない可能性があります。"
    else
        echo "警告: 認識されないMySQLバージョンです: $MYSQL_VERSION"
    fi
    
    end_message
fi

echo "すべてのリポジトリ設定が完了しました。"