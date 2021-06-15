#!/bin/sh
PS3="インストールしたいPHPのバージョンを選んでください > "
ITEM_LIST="PHP7.3 PHP7.4 PHP8.0"

select selection in $ITEM_LIST
do
  if [ $selection = "PHP7.3" ]; then
    # php7系のインストール
    echo "php7.3をインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php73 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break

  elif [ $selection = "PHP7.4" ]; then
    # php7系のインストール
    echo "php7.4をインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php74 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break

  elif [ $selection = "PHP8.0" ]; then
    # php8系のインストール
    echo "php8.0をインストールします"
    echo ""
    start_message
    yum -y install --enablerepo=remi,remi-php80 php php-mbstring php-xml php-xmlrpc php-gd php-pdo php-pecl-mcrypt php-mysqlnd php-pecl-mysql
    echo "phpのバージョン確認"
    echo ""
    php -v
    echo ""
    end_message
    break

  else
    echo "どちらかを選択してください"
  fi
done

#php.iniの設定変更
start_message
echo "phpのバージョンを非表示にします"
echo "sed -i -e s|expose_php = On|expose_php = Off| /etc/php.ini"
sed -i -e "s|expose_php = On|expose_php = Off|" /etc/php.ini
echo "phpのタイムゾーンを変更"
echo "sed -i -e s|;date.timezone =|date.timezone = Asia/Tokyo| /etc/php.ini"
sed -i -e "s|;date.timezone =|date.timezone = Asia/Tokyo|" /etc/php.ini
end_message

# phpinfoの作成
start_message
touch /var/www/html/info.php
echo '<?php phpinfo(); ?>' >> /var/www/html/info.php
cat /var/www/html/info.php
end_message
