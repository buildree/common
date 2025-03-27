#!/bin/sh

<<COMMENT


RedHat系のアップデートを実行

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

echo "システムを最新版に更新します"
echo ""
dnf -y update
