#!/bin/sh
#pyenvの設定
start_message
echo "gitでpyenvをクーロンします"
git clone git://github.com/yyuu/pyenv.git /usr/local/pyenv
git clone git://github.com/yyuu/pyenv-virtualenv.git /usr/local/pyenv/plugins/pyenv-virtualenv
end_message

#pyenvのインストール
start_message
echo "起動時に読み込まれるようにします"
cat >/etc/profile.d/pyenv.sh <<'EOF'
export PYENV_ROOT="/usr/local/pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
eval "$(pyenv init --path)"
EOF

source /etc/profile.d/pyenv.sh
end_message

#pythonの確認
start_message
echo "pythonのリスト確認"
pyenv install --list
echo "python3.9.5のインストール"
env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.9.5
echo "pythonの設定を変更"
pyenv global 3.9.5
end_message

#pythonの確認
start_message
echo "pythonの位置を確認"
which python
echo "pythonのバージョン確認"
python --version
end_message

#pipのアップグレード
start_message
echo "pipのアップグレード"
pip install --upgrade pip
end_message
