#!/bin/sh

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

CentOSのアップデートを実行

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

#公式リポジトリの追加
start_message
rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
yum info mysql-community-server
end_message

#MySQLのインストール
start_message
echo "MySQLのインストール"
echo ""
yum -y install mysql-community-server --enablerepo=mysql80-community
yum list installed | grep mysql
end_message

#バージョン確認
start_message
echo "MySQLのバージョン確認"
echo ""
mysql --version
end_message

#my.cnfの設定を変える
start_message
echo "ファイル名をリネーム"
echo "/etc/my.cnf.default"
mv /etc/my.cnf /etc/my.cnf.default

echo "新規ファイルを作成してパスワードを無制限使用に変える"
cat <<EOF >/etc/my.cnf
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
slow_query_log_file=/var/log/mysql-slow.log
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
systemctl status mysqld.service
end_message
#パスワード設定
start_message
DB_PASSWORD=$(grep "A temporary password is generated" /var/log/mysqld.log | sed -s 's/.*root@localhost: //')
#sed -i -e "s|#password =|password = '${DB_PASSWORD}'|" /etc/my.cnf
mysql -u root -p${DB_PASSWORD} --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${RPASSWORD}'; flush privileges;"
echo ${RPASSWORD}

cat <<EOF >/etc/createdb.sql
CREATE DATABASE centos;
CREATE USER 'centos'@'localhost' IDENTIFIED BY '${UPASSWORD}';
GRANT ALL PRIVILEGES ON centos.* TO 'centos'@'localhost';
FLUSH PRIVILEGES;
SELECT user, host FROM mysql.user;
EOF
mysql -u root -p${RPASSWORD}  -e "source /etc/createdb.sql"

end_message

#ファイルを保存
cat <<EOF >/etc/my.cnf.d/centos.cnf
[client]
user = centos
password = ${UPASSWORD}
host = localhost
EOF

systemctl restart mysqld.service

#ファイルの保存
start_message
echo "パスワードなどを保存"
cat <<EOF >/root/pass.txt
root = ${RPASSWORD}
centos = ${UPASSWORD}
EOF
end_message


#cnfファイルの表示
cat /etc/my.cnf
