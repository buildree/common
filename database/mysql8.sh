#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://www.logw.jp/

注意点：conohaのポートは全て許可前提となります。MariaDBがインストールされていない状態となります。

目的：システム更新+MySQL8のインストール
・MySQL8


COMMENT

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

#unicorn7か確認
if [ -e /etc/redhat-release ]; then
    DIST="redhat"
    DIST_VER=`cat /etc/redhat-release | sed -e "s/.*\s\([0-9]\)\..*/\1/"`

    if [ $DIST = "redhat" ];then
      if [ $DIST_VER = "7" ];then

      start_message
        rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
        yum info mysql-community-server
        end_message
        break #強制終了

        #RedHat系8
        elif [ $DIST_VER = "8" ];then
        start_message
        rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el8-1.noarch.rpm
        yum info mysql-community-server
        end_message
        break #強制終了

        elif [ $DIST_VER = "9" ];then
        start_message
        rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
        yum info mysql-community-server
        end_message
        break #強制終了

        else
        echo "どれでもない"
        fi

        #GCPキー更新
        rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022


        #元のMySQLを無効化
        dnf module disable -y mysql

        #インストール
        start_message
        echo "MySQLのインストール"
        echo "dnf install mysql-community-server"
        dnf install -y mysql-community-server
        end_message

        #バージョン確認
        start_message
        echo "MySQLのバージョン確認"
        echo ""
        mysqld --version
        end_message

        #my.cnfの設定を変える
        start_message
        echo "ファイル名をリネーム"
        echo "/etc/my.cnf.default"
        mv /etc/my.cnf /etc/my.cnf.default
        mv /etc/my.cnf.d/mysql-server.cnf /etc/my.cnf.d/mysql-server.cnf.default

        echo "新規ファイルを作成してパスワードを無制限使用に変える"
cat <<EOF > /etc/my.cnf
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/8.0/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove the leading "# " to disable binary logging
# Binary logging captures changes between backups and is enabled by
# default. It's default setting is log_bin=binlog
# disable_log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
#
# Remove leading # to revert to previous value for default_authentication_plugin,
# this will increase compatibility with older clients. For background, see:
# https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_default_authentication_plugin
# default-authentication-plugin=mysql_native_password

datadir=/var/lib/mysql
log-error=/var/log/mysqld.log
socket=/var/lib/mysql/mysql.sock

character-set-server = utf8mb4
collation-server = utf8mb4_bin
default_password_lifetime = 0

#slowクエリの設定
slow_query_log=ON
slow_query_log_file=/var/log/mysql/mysql-slow.log
long_query_time=0.01
EOF
        end_message

        #自動起動
        start_message
        echo "MySQLの自動起動を設定"
        echo ""
        systemctl enable mysqld.service
        end_message

        #自動起動
        start_message
        echo "MySQLの起動"
        echo ""
        systemctl start mysqld.service
        end_message

        #パスワード設定
        start_message
        echo "パスワード"
        #DBrootユーザーのパスワード
        RPASSWORD=$(more /dev/urandom  | tr -dc '12345678abcdefghijkmnpqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ,.+\-\!' | fold -w 12 | grep -i [12345678] | grep -i '[,.+\-\!]' | head -n 1)
        #DBuser(unicorn)パスワード
        UPASSWORD=$(more /dev/urandom  | tr -dc '12345678abcdefghijkmnpqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ,.+\-\!' | fold -w 12 | grep -i [12345678] | grep -i '[,.+\-\!]' | head -n 1)

        DB_PASSWORD=$(grep "A temporary password is generated" /var/log/mysqld.log | sed -s 's/.*root@localhost: //')
        #sed -i -e "s|#password =|password = '${DB_PASSWORD}'|" /etc/my.cnf
        mysql -u root -p${DB_PASSWORD} --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${RPASSWORD}'; flush privileges;"
        echo ${RPASSWORD}

        cat <<EOF >/etc/createdb.sql
CREATE DATABASE unicorn;
CREATE USER 'unicorn'@'localhost' IDENTIFIED BY '${UPASSWORD}';
GRANT ALL PRIVILEGES ON unicorn.* TO 'unicorn'@'localhost';
FLUSH PRIVILEGES;
SELECT user, host FROM mysql.user;
EOF
        mysql -u root -p${RPASSWORD}  -e "source /etc/createdb.sql"

        end_message

        #ファイルを保存
        cat <<EOF >/etc/my.cnf.d/unicorn.cnf
[client]
user = unicorn
password = ${UPASSWORD}
host = localhost
EOF

        systemctl restart mysqld.service

        #ファイルの保存
        start_message
        echo "パスワードなどを保存"
        cat <<EOF >/root/pass.txt
root = ${RPASSWORD}
unicorn = ${UPASSWORD}
EOF
        end_message


        #cnfファイルの表示





        echo ""
        echo ""
        cat <<EOF
ステータスがアクティブの場合は起動成功です

---------------------------------------------
MySQLのポリシーではパスワードは
"8文字以上＋大文字小文字＋数値＋記号"
でないといけないみたいです

MySQLへのログイン方法
unicornユーザーでログインするには下記コマンドを実行してください
mysql --defaults-extra-file=/etc/my.cnf.d/unicorn.cnf
---------------------------------------------
・slow queryはデフォルトでONとなっています
・秒数は0.01秒となります
・/root/pass.txtにパスワードが保存されています
---------------------------------------------
EOF
        echo "データベースのrootユーザーのパスワードは"${RPASSWORD}"です。"
        echo "データベースのunicornユーザーのパスワードは"${UPASSWORD}"です。"

      else
        echo "unicorn7ではないため、このスクリプトは使えません。このスクリプトのインストール対象はunicorn7です。"
      fi
    fi

else
  echo "このスクリプトのインストール対象はunicorn7です。unicorn7以外は動きません。"
  cat <<EOF
  検証LinuxディストリビューションはDebian・Ubuntu・Fedora・Arch Linux（アーチ・リナックス）となります。
EOF
fi
