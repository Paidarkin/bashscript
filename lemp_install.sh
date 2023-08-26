 #!/bin/bash
# This script automatically installs nginx, PHP and MySQL (community version) 
# with the ability to choose two versions of nginx: Stable and Mainline, 
# choose one of the two versions of MySQL (5.7, 8.0) and also choose one of
# the three versions of PHP (5.4, 7.4, 8.2). This script tested on CentOS 7.
# Checking for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi
#Here you can set up the future value for root password in MySQL
mysqlrootpass="1Q@Z2wsx"

echo "[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/7/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key" > /etc/yum.repos.d/nginx.repo 

sudo yum -y install yum-utils
echo "Nginx stable repo configuration completed."

# Listing Nginx versions
echo "Available Nginx versions:"
echo "1 -  Stable version"
echo "2 -  Mainline version"
# Requesting user to choose a version
read -p "Enter the number corresponding to the desired Nginx version: " nginxversion
# Listing MySQL versions 
echo "Available MySQL community server versions:"
echo "1) 5.7 version"
echo "2) 8.0 version"
# Requesting user to choose a version
read -p "Enter the number corresponding to the desired MySQL version: " mysqlver
# Listing PHP versions 
echo "Available PHP versions:"
echo "1) PHP 5.4"
echo "2) PHP 7.4"
echo "3) PHP 8.2"
# Requesting user to choose a version
read -p "Enter the number corresponding to the desired PHP version: " phpversion

# Including Nginx repository depending on user's selection
case $nginxversion in
    1)
        echo "Installing Stable version of Nginx..."
        sudo yum install -y epel-release
        sudo yum install -y nginx
        ;;
    2)
        echo "Installing Mainline version of Nginx..."
        sudo yum install -y epel-release

      	sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/nginx.repo
	awk 'BEGIN{count=0} /enabled=0/ {count++; if(count==2) sub("enabled=0", "enabled=1")} {print}' /etc/yum.repos.d/nginx.repo > /var/tmp1.txt && mv /var/tmp1.txt /etc/yum.repos.d/nginx.repo -f
        sudo yum install -y nginx
        ;;
    *)
        echo "Invalid choice of NGINX. Exiting..."
        exit 1
        ;;
esac

echo "Starting Nginx..."
systemctl start nginx

#  Nginx on system startup
echo "Enabling Nginx on startup..."
systemctl enable nginx
########################## mysql part  _______
yum install -y https://repo.mysql.com//mysql80-community-release-el7-10.noarch.rpm

# Добавление репозитория MySQL в зависимости от выбора и установка 
case $mysqlver in
    1)
        echo "Installing 5.7 version of MySQL..."
        yum-config-manager --disable mysql80-community | grep enabled
	yum-config-manager --enable mysql57-community  | grep enabled
        yum update -y
	yum install mysql-community-server -y
        ;;
    2)
        echo "Installing 8.0 version of MySQL..."
	yum-config-manager --disable mysql57-community  | grep enabled
	yum-config-manager --enable mysql80-community | grep enabled
        yum update -y	
	yum install mysql-community-server -y
        ;;
    *)
        echo "Invalid choice of MySQL. Exiting..."
        exit 1
        ;;
esac

echo "Starting MySQL..."
systemctl start mysqld
#Setting a password !QAZ2wsx for the root user in MySQL
temp_password=$(grep password /var/log/mysqld.log | awk '{print $NF}')
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$mysqlrootpass'; flush privileges;" > reset_pass.sql
mysql -u root --password="$temp_password" --connect-expired-password < reset_pass.sql
rm -f reset_pass.sql
################# php part _______________
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum update -y

# Requesting user to choose a version
case $phpversion in
    1)
        echo "Enabling PHP 5.4 repository..."
        yum-config-manager --enable remi-php54
        ;;
    2)
        echo "Enabling PHP 7.4 repository..."
        yum-config-manager --enable remi-php74
        ;;
    3)
        echo "Enabling PHP 8.2 repository..."
        yum-config-manager --enable remi-php82
        ;;
    *)
        echo "Invalid choice of PHP. Exiting..."
        exit 1
        ;;
esac
yum update -y
echo "Installing PHP components..."
yum install -y php php-cli php-fpm

# Restart PHP-FPM
echo "Restarting PHP-FPM..."
systemctl start php-fpm

#PHP-FPM on system startup  
echo "Enabling PHP-FPM on startup..."                
systemctl enable php-fpm
#_____________________health checks
# Checking Nginx status
systemctl status nginx
nginx -v
ss -tuln | grep 80
if  systemctl status nginx | grep active
   then
      echo -e "\033[32m Nginx installation and configuration completed.\033[0m"
   else
     echo -e "\033[31mNginx installation and configuration NOT completed. =(\033[0m"
fi	
# Checking PHP-FPM status
systemctl status php-fpm
# Checking PHP version
php -v
if  systemctl status php-fpm | grep active
   then
      echo -e "\033[32m PHP installation and configuration completed.\033[0m"
   else
     echo -e "\033[31mPHP installation and configuration NOT completed. =(\033[0m"
fi	
# Checking MySQL status
systemctl status mysqld
mysql --version
mysql -u root -p$mysqlrootpass -e "show databases;"
if  systemctl status mysqld | grep active
   then
      echo -e "\033[32mMySQL community server installation and configuration completed.\033[0m"
   else
     echo -e "\033[31mMySQL community server installation and configuration NOT completed. =(\033[0m"
fi	
