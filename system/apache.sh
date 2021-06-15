#!/bin/sh
# apacheのインストール
echo "apacheをインストールします"
echo ""

PS3="インストールしたいapacheのバージョンを選んでください > "
ITEM_LIST="apache2.4.6 apache2.4.x"

select selection in $ITEM_LIST

do
  if [ $selection = "apache2.4.6" ]; then
    # apache2.4.6のインストール
    echo "apache2.4.6をインストールします"
    echo ""
    start_message
    yum -y install httpd
    yum -y install openldap-devel expat-devel
    yum -y install httpd-devel mod_ssl
    end_message
    break
  elif [ $selection = "apache2.4.x" ]; then
    # 2.4.ｘのインストール
    #IUSリポジトリのインストール
    start_message
    echo "IUSリポジトリをインストールします"
    yum -y install https://repo.ius.io/ius-release-el7.rpm
    end_message

    #IUSリポジトリをデフォルトから外す
    start_message
    echo "IUSリポジトリをデフォルトから外します"
    cat >/etc/yum.repos.d/ius.repo <<'EOF'
[ius]
name = IUS for Enterprise Linux 7 - $basearch
baseurl = https://repo.ius.io/7/$basearch/
enabled = 1
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

[ius-debuginfo]
name = IUS for Enterprise Linux 7 - $basearch - Debug
baseurl = https://repo.ius.io/7/$basearch/debug/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

[ius-source]
name = IUS for Enterprise Linux 7 - Source
baseurl = https://repo.ius.io/7/src/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7
EOF
    end_message

    #Nghttp2のインストール
    start_message
    echo "Nghttp2のインストール"
    yum --enablerepo=epel -y install nghttp2
    end_message

    #mailcapのインストール
    start_message
    echo "mailcapのインストール"
    yum -y install mailcap
    end_message


    # apacheのインストール
    echo "apacheをインストールします"
    echo ""

    start_message
    yum -y --enablerepo=ius install httpd24u
    yum -y install openldap-devel expat-devel
    yum -y --enablerepo=ius install httpd24u-devel httpd24u-mod_ssl
    break
  else
    echo "どちらかを選択してください"
  fi
done

echo "ファイルのバックアップ"
echo ""
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bk

echo "htaccess有効化した状態のconfファイルを作成します"
echo ""

sed -i -e "151d" /etc/httpd/conf/httpd.conf
sed -i -e "151i AllowOverride All" /etc/httpd/conf/httpd.conf
sed -i -e "350i #バージョン非表示" /etc/httpd/conf/httpd.conf
sed -i -e "351i ServerTokens ProductOnly" /etc/httpd/conf/httpd.conf
sed -i -e "352i ServerSignature off \n" /etc/httpd/conf/httpd.conf


#SSLの設定変更
echo "ファイルのバックアップ"
echo ""
cp /etc/httpd/conf.modules.d/00-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf.bk


ls /etc/httpd/conf/
echo "Apacheのバージョン確認"
echo ""
httpd -v
echo ""
end_message

#gzip圧縮の設定
cat >/etc/httpd/conf.d/gzip.conf <<'EOF'
SetOutputFilter DEFLATE
BrowserMatch ^Mozilla/4 gzip-only-text/html
BrowserMatch ^Mozilla/4\.0[678] no-gzip
BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
SetEnvIfNoCase Request_URI\.(?:gif|jpe?g|png)$ no-gzip dont-vary
Header append Vary User-Agent env=!dont-var
EOF
