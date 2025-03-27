#!/bin/bash

# OS名とメジャーバージョンを検出する関数
# 目的：
# - /etc/os-releaseまたは/etc/redhat-releaseからOSの正確な名前とメジャーバージョンを取得
# - CentOS Stream含む、各種RHELベースOSに対応
detect_os_version() {
    local major_version=""
    local os_name=""

    # /etc/os-releaseを優先的に使用
    # 最新の標準的な方法でOS情報を取得
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        os_name=$NAME
        major_version=$(echo "$VERSION_ID" | cut -d. -f1)
    fi

    # os-releaseで情報が取得できない場合は/etc/redhat-releaseを確認
    # 古いディストリビューションや特殊なケースに対応
    if [ -z "$major_version" ] && [ -f /etc/redhat-release ]; then
        # CentOS Streamの特別な判定
        # 他のRHEL系ディストリビューションと異なる形式に対応
        if grep -q "CentOS Stream" /etc/redhat-release; then
            os_name="CentOS Stream"
            major_version=$(grep -o -E '^[0-9]+' /etc/redhat-release)
        else
            # その他のRHEL系ディストリビューション
            os_name=$(cat /etc/redhat-release | cut -d' ' -f1)
            major_version=$(grep -o -E '^[0-9]+' /etc/redhat-release)
        fi
    fi

    # グローバル変数に検出した情報を設定
    # 他のスクリプトで利用可能
    DETECTED_OS_NAME="$os_name"
    DETECTED_OS_MAJOR_VERSION="$major_version"
}

# RHELベースのOSかどうかをチェックする関数
# 目的：
# - /etc/redhat-releaseの存在を確認
# - RHELベースのディストリビューションであることを判定
is_rhel_based() {
    if [ -e /etc/redhat-release ]; then
        return 0  # true
    else
        return 1  # false
    fi
}

# OSバージョンが8以上かどうかをチェックする関数
# 目的：
# - インストールスクリプトが実行可能なOSバージョンであることを確認
# - サポート対象のRHEL系OSであるRocky, AlmaLinux, RHEL, CentOS Stream等の8以降のバージョンを判定
is_supported_version() {
    # OS情報を再検出
    detect_os_version
    
    # RHELベースOSであり、かつメジャーバージョンが8以上であることを確認
    if is_rhel_based; then
        if [ "$DETECTED_OS_MAJOR_VERSION" -ge 8 ]; then
            return 0  # true
        fi
    fi
    
    return 1  # false
}

# コマンドライン引数に応じて関数を呼び出す
# 目的：
# - スクリプトを直接実行した際の柔軟な情報表示
# - デバッグや確認用の機能を提供
case "$1" in
    detect)
        # OSの詳細情報を表示
        detect_os_version
        echo "OS Name: $DETECTED_OS_NAME"
        echo "Major Version: $DETECTED_OS_MAJOR_VERSION"
        ;;
    check)
        # インストール可能なOSかどうかを判定し、結果を表示
        if is_rhel_based && is_supported_version; then
            echo "OSは要件を満たしています。インストールを続行できます。"
            exit 0
        else
            echo "サポートされていないOSまたはバージョンです。インストールを中止します。"
            exit 1
        fi
        ;;
    *)
        # 不正な引数が渡された場合のヘルプメッセージ
        echo "使用法: $0 {detect|check}"
        echo "  detect: OSの情報を表示"
        echo "  check:  インストール可能なOSかどうかを確認"
        exit 1
        ;;
esac