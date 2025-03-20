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

# ユーザー名
USERNAME='unicorn'
PASSWORD=$(< /dev/urandom tr -dc '[:alnum:]' | head -c32)

       # まずユーザーを作成
       useradd -m -s /bin/bash $USERNAME
       if [ $? -ne 0 ]; then
         echo "ユーザー作成に失敗しました。"
         exit 1
       fi
#パスワードの設定
echo "$PASSWORD" | passwd --stdin $USERNAME

# .sshディレクトリの作成と権限設定
mkdir -p /home/${USERNAME}/.ssh
chmod 700 /home/${USERNAME}/.ssh

# ed25519鍵の生成
ssh-keygen -t ed25519 -N "" -f /home/${USERNAME}/.ssh/${USERNAME}


# 公開鍵の権限設定
chmod 644 /home/${USERNAME}/.ssh/${USERNAME}.pub
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh

# 公開鍵をauthorized_keysに追加
cat /home/${USERNAME}/.ssh/${USERNAME}.pub >> /home/${USERNAME}/.ssh/authorized_keys

# authorized_keysの権限設定
chmod 600 /home/${USERNAME}/.ssh/authorized_keys

# 秘密鍵のパーミッションを設定
chmod 600 /home/${USERNAME}/.ssh/${USERNAME}

# 秘密鍵をユーザーのホームディレクトリに移動
cp /home/${USERNAME}/.ssh/${USERNAME} /home/${USERNAME}/
chown ${USERNAME}:${USERNAME} /home/${USERNAME}/${USERNAME}

# 安全のために元の場所の秘密鍵は削除
rm /home/${USERNAME}/.ssh/${USERNAME}

echo "ed25519 SSH鍵が生成されました。"
echo "秘密鍵: /home/${USERNAME}/${USERNAME}"
echo "公開鍵: /home/${USERNAME}/.ssh/${USERNAME}.pub"
echo ""
echo "秘密鍵が /home/${USERNAME}/${USERNAME} に移動されました。"
echo "秘密鍵のパーミッションは 600 に設定されています。"
echo "このファイルを安全な方法でクライアントマシンに移動し、サーバーからは削除することを強く推奨します。"
echo "秘密鍵はサーバー上に保管せず、使用するクライアントマシンにのみ保管してください。"
echo "公開鍵をクライアントマシンの ~/.ssh/authorized_keys ファイルに追加してください。"
echo "必要に応じて、秘密鍵にパスフレーズを設定してください。"
echo "ユーザーのパスワードはランダムで生成されています。セキュリティの関係上表示したりファイルに残していないので新しく設定してください。"
end_message