#!/bin/sh

#rootユーザーで実行 or sudo権限ユーザー

<<COMMENT
作成者：サイトラボ
URL：https://www.site-lab.jp/
URL：https://buildree.com/

CentOSで使うユーザーの作成

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

#ユーザー作成
start_message
echo "centosユーザーを作成します"
USERNAME='centos'
PASSWORD=$(more /dev/urandom  | tr -d -c '[:alnum:]' | fold -w 10 | head -1)

useradd -m -G apache -s /bin/bash "${USERNAME}"
echo "${PASSWORD}" | passwd --stdin "${USERNAME}"
echo "パスワードは"${PASSWORD}"です。"

#所属グループ表示
echo "所属グループを表示します"
getent group apache
end_message
