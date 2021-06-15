#!/bin/sh

#ユーザー作成
start_message
echo "centosユーザーを作成します"
USERNAME='centos'
PASSWORD=$(more /dev/urandom  | tr -d -c '[:alnum:]' | fold -w 10 | head -1)

useradd -m -G nobody -s /bin/bash "${USERNAME}"
echo "${PASSWORD}" | passwd --stdin "${USERNAME}"
echo "パスワードは"${PASSWORD}"です。"
end_message

umask 0002

#ファイルの保存
start_message
echo "パスワードなどを保存"
cat <<EOF >/root/pass.txt
ログインユーザー
centos = ${PASSWORD}
EOF
