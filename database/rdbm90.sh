#!/bin/bash

<<COMMENT
作成者：サイトラボ（改善版）
URL：https://buildree.com/

目的：AlmaLinux/RHEL系システムにMySQL 9.0をセキュアにインストール
前提：スクリプト内でMySQL公式リポジトリを追加
COMMENT

# ログ関数
log_message() {
  echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] $1\n"
}

# エラーハンドリング関数
handle_error() {
  log_message "エラーが発生しました: $1"
  exit 1
}

# 警告関数 - エラーを出すが処理を続行
warn_message() {
  log_message "警告: $1 - 処理を続行します"
}

# ディストリビューションのバージョン確認
DIST_VER=$(rpm -E %{rhel})
log_message "検出したディストリビューションバージョン: $DIST_VER"

# MySQL 9.0公式リポジトリの追加
log_message "MySQL 9.0リポジトリを追加しています..."

if [ "$DIST_VER" = "8" ]; then
  log_message "RHEL/AlmaLinux 8向けのリポジトリをインストールします"
  rpm -ivh https://dev.mysql.com/get/mysql-community-server-9.0.1-1.el8.x86_64.rpm || warn_message "リポジトリのインストールに問題がありました"
  
elif [ "$DIST_VER" = "9" ]; then
  log_message "RHEL/AlmaLinux 9向けのリポジトリをインストールします"
  rpm -ivh https://dev.mysql.com/get/Downloads/MySQL-9.0/mysql-community-server-9.0.1-1.el9.x86_64.rpm || warn_message "リポジトリのインストールに問題がありました"
  
else
  handle_error "サポートされていないディストリビューションバージョンです: $DIST_VER"
fi

# GPGキーのインポート
log_message "MySQL GPGキーをインポートしています..."
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 || warn_message "GPGキーのインポートに失敗しました"

# 元のMySQLモジュールを無効化（存在する場合のみ）
log_message "既存のMySQLモジュールの確認と無効化を試みています..."
if dnf module list mysql &>/dev/null; then
  log_message "MySQLモジュールが存在します。無効化を試みます..."
  dnf module disable -y mysql || warn_message "MySQLモジュールの無効化に失敗しました"
else
  log_message "システムにMySQLモジュールが見つかりません。無効化をスキップします。"
fi

# インストール
log_message "MySQL 9.0 Community Serverをインストールしています..."
dnf install -y mysql-community-server || handle_error "MySQLのインストールに失敗しました"

# バージョン確認
log_message "MySQLのバージョン確認:"
mysqld --version || handle_error "MySQLバージョン確認に失敗しました"

# my.cnfの設定を変える
log_message "MySQL設定ファイルを構成しています..."
# バックアップを作成
if [ -f /etc/my.cnf ]; then
  mv /etc/my.cnf /etc/my.cnf.backup.$(date +%Y%m%d%H%M%S) || handle_error "my.cnfのバックアップに失敗しました"
fi

if [ -f /etc/my.cnf.d/mysql-server.cnf ]; then
  mv /etc/my.cnf.d/mysql-server.cnf /etc/my.cnf.d/mysql-server.cnf.backup.$(date +%Y%m%d%H%M%S) || handle_error "mysql-server.cnfのバックアップに失敗しました"
fi

# Slowクエリログディレクトリの作成
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

# 新しい設定ファイルを作成
cat <<EOF > /etc/my.cnf
# MySQL 9.0 設定ファイル
# 参考: http://dev.mysql.com/doc/refman/9.0/en/server-configuration-defaults.html

[mysqld]
# 基本設定
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

# 文字コード設定
character-set-server = utf8mb4
collation-server = utf8mb4_bin

# セキュリティ設定
default_password_lifetime = 0
max_allowed_packet = 16M
max_connections = 151
bind-address = 127.0.0.1

# パフォーマンス設定
innodb_buffer_pool_size = 128M
join_buffer_size = 2M
sort_buffer_size = 2M
read_rnd_buffer_size = 2M

# Slowクエリログ設定
slow_query_log = ON
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 1.0
log_queries_not_using_indexes = ON

# タイムアウト設定
interactive_timeout = 28800
wait_timeout = 28800

# MySQL 9.0の新機能設定
# 注: MySQL 9.0の新機能に合わせてここにパラメータを追加

[client]
default-character-set = utf8mb4
EOF

# MySQL自動起動を設定
log_message "MySQLの自動起動を設定しています..."
systemctl enable mysqld.service || handle_error "自動起動の設定に失敗しました"

# MySQLの起動
log_message "MySQLを起動しています..."
systemctl start mysqld.service || handle_error "MySQLの起動に失敗しました"

# パスワード設定
log_message "MySQLのセキュリティ設定を行っています..."

# 一時パスワードを取得
DB_PASSWORD=$(grep "A temporary password is generated" /var/log/mysqld.log | sed -s 's/.*root@localhost: //')
if [ -z "$DB_PASSWORD" ]; then
  handle_error "MySQLの一時パスワードを取得できませんでした"
fi

# パスワードの生成（MySQLポリシーに準拠したパスワードを生成）
RPASSWORD=$(openssl rand -base64 16 | sed 's/[^a-zA-Z0-9]/#/g' | sed 's/^\([a-z]*\)/\u\1/g' | sed 's/$/@1A/')
UPASSWORD=$(openssl rand -base64 16 | sed 's/[^a-zA-Z0-9]/#/g' | sed 's/^\([a-z]*\)/\u\1/g' | sed 's/$/@1A/')

# rootパスワードの変更
log_message "MySQLのrootパスワードを変更しています..."
mysql -u root -p"${DB_PASSWORD}" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${RPASSWORD}'; FLUSH PRIVILEGES;" || handle_error "rootパスワードの変更に失敗しました"

# DBとユーザーの作成
log_message "アプリケーション用のデータベースとユーザーを作成しています..."
cat <<EOF >/tmp/createdb.sql
CREATE DATABASE IF NOT EXISTS unicorn DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS 'unicorn'@'localhost' IDENTIFIED BY '${UPASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON unicorn.* TO 'unicorn'@'localhost';
FLUSH PRIVILEGES;
SELECT user, host FROM mysql.user;
EOF

mysql -u root -p"${RPASSWORD}" -e "source /tmp/createdb.sql" || handle_error "データベースとユーザーの作成に失敗しました"
rm -f /tmp/createdb.sql  # 一時ファイルを削除

# クライアント設定ファイルを保存（600権限で）
log_message "クライアント設定ファイルを作成しています..."
cat <<EOF >/etc/my.cnf.d/unicorn.cnf
[client]
user = unicorn
password = '${UPASSWORD}'
host = localhost
EOF
chmod 600 /etc/my.cnf.d/unicorn.cnf

# MySQLサービスの再起動
log_message "MySQLサービスを再起動しています..."
systemctl restart mysqld.service || handle_error "MySQLの再起動に失敗しました"

# パスワードの保存（600権限で）
log_message "認証情報を保存しています..."
cat <<EOF >/root/mysql_credentials.txt
# MySQL 9.0認証情報 - $(date '+%Y-%m-%d %H:%M:%S')に生成
# このファイルは機密情報を含みます。適切に保護してください。
root_user = root
root_password = ${RPASSWORD}
app_user = unicorn
app_password = ${UPASSWORD}
database = unicorn
mysql_version = 9.0
EOF
chmod 600 /root/mysql_credentials.txt

log_message "MySQLのセキュリティ強化を実施しています..."
# 追加のセキュリティ設定（不要なアカウントの削除、リモートrootログイン無効化など）
mysql -u root -p"${RPASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

log_message "MySQL 9.0のインストールと設定が完了しました"
log_message "認証情報は /root/mysql_credentials.txt に保存されています"
log_message "セキュリティのため、重要な環境では認証情報をより安全な場所に移動することを検討してください"