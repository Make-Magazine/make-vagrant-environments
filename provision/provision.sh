# provision.sh
#
# This file is specified in Vagrantfile and is loaded by Vagrant as the primary
# provisioning script whenever the commands `vagrant up`, `vagrant provision`,
# or `vagrant reload` are used. It provides all of the default packages and
# configurations included with Varying Vagrant Vagrants.

# By storing the date now, we can calculate the duration of provisioning at the
# end of this script.
start_seconds=`date +%s`

# Capture a basic ping result to Google's primary DNS server to determine if
# outside access is available to us. If this does not reply after 2 attempts,
# we try one of Level3's DNS servers as well. If neither of these IPs replies to
# a ping, then we'll skip a few things further in provisioning rather than
# creating a bunch of errors.
ping_result=`ping -c 2 8.8.4.4 2>&1`
if [[ $ping_result != *bytes?from* ]]
then
	ping_result=`ping -c 2 4.2.2.2 2>&1`
fi

# PACKAGE INSTALLATION
#
# Build a bash array to pass all of the packages we want to install to a single
# apt-get command. This avoids doing all the leg work each time a package is
# set to install. It also allows us to easily comment out or add single
# packages. We set the array as empty to begin with so that we can append
# individual packages to it as required.
apt_package_install_list=()

# Start with a bash array containing all packages we want to install in the
# virtual machine. We'll then loop through each of these and check individual
# status before adding them to the apt_package_install_list array.
apt_package_check_list=(

	# PHP5
	#
	# Our base packages for php5. As long as php5-fpm and php5-cli are
	# installed, there is no need to install the general php5 package, which
	# can sometimes install apache as a requirement.
	php5-fpm
	php5-cli

	# Common and dev packages for php
	php5-common
	php5-dev

	# Extra PHP modules that we find useful
	php5-memcache
	php5-imagick
	php5-xdebug
	php5-mcrypt
	php5-mysql
	php5-imap
	php5-curl
	php-pear
	php5-gd
	php-apc

	# nginx is installed as the default web server
	nginx

	# memcached is made available for object caching
	memcached

	# mysql is the default database
	mysql-server

	# other packages that come in handy
	imagemagick
	subversion
	git-core
	unzip
	ngrep
	curl
	make
	vim
	colordiff

	# Req'd for Webgrind
	graphviz

	# dos2unix
	# Allows conversion of DOS style line endings to something we'll have less
	# trouble with in Linux.
	dos2unix
)

echo "Check for apt packages to install..."

# Loop through each of our packages that should be installed on the system. If
# not yet installed, it should be added to the array of packages to install.
for pkg in "${apt_package_check_list[@]}"
do
	package_version=`dpkg -s $pkg 2>&1 | grep 'Version:' | cut -d " " -f 2`
	if [[ $package_version != "" ]]
	then
		space_count=`expr 20 - "${#pkg}"` #11
		pack_space_count=`expr 30 - "${#package_version}"`
		real_space=`expr ${space_count} + ${pack_space_count} + ${#package_version}`
		printf " * $pkg %${real_space}.${#package_version}s ${package_version}\n"
	else
		echo " *" $pkg [not installed]
		apt_package_install_list+=($pkg)
	fi
done

# MySQL
#
# Use debconf-set-selections to specify the default password for the root MySQL
# account. This runs on every provision, even if MySQL has been installed. If
# MySQL is already installed, it will not affect anything. The password in the
# following two lines *is* actually set to the word 'blank' for the root user.
echo mysql-server mysql-server/root_password password blank | debconf-set-selections
echo mysql-server mysql-server/root_password_again password blank | debconf-set-selections

# Provide our custom apt sources before running `apt-get update`
ln -sf /srv/config/apt-source-append.list /etc/apt/sources.list.d/vvv-sources.list | echo "Linked custom apt sources"

if [[ $ping_result == *bytes?from* ]]
then
	# If there are any packages to be installed in the apt_package_list array,
	# then we'll run `apt-get update` and then `apt-get install` to proceed.
	if [ ${#apt_package_install_list[@]} = 0 ];
	then
		printf "No apt packages to install.\n\n"
	else
		# Before running `apt-get update`, we should add the public keys for
		# the packages that we are installing from non standard sources via
		# our appended apt source.list

		# Nginx.org nginx key ABF5BD827BD9BF62
		gpg -q --keyserver keyserver.ubuntu.com --recv-key ABF5BD827BD9BF62
		gpg -q -a --export ABF5BD827BD9BF62 | apt-key add -

		# Launchpad Subversion key EAA903E3A2F4C039
		gpg -q --keyserver keyserver.ubuntu.com --recv-key EAA903E3A2F4C039
		gpg -q -a --export EAA903E3A2F4C039 | apt-key add -

		# Launchpad PHP key 4F4EA0AAE5267A6C
		gpg -q --keyserver keyserver.ubuntu.com --recv-key 4F4EA0AAE5267A6C
		gpg -q -a --export 4F4EA0AAE5267A6C | apt-key add -

		# Launchpad git key A1715D88E1DF1F24
		gpg -q --keyserver keyserver.ubuntu.com --recv-key A1715D88E1DF1F24
		gpg -q -a --export A1715D88E1DF1F24 | apt-key add -

		# update all of the package references before installing anything
		printf "Running apt-get update....\n"
		apt-get update --assume-yes

		# install required packages
		printf "Installing apt-get packages...\n"
		apt-get install --assume-yes ${apt_package_install_list[@]}

		# Clean up apt caches
		apt-get clean
	fi

	# ack-grep
	#
	# Install ack-rep directory from the version hosted at beyondgrep.com as the
	# PPAs for Ubuntu Precise are not available yet.
	if [ -f /usr/bin/ack ]
	then
		echo "ack-grep already installed"
	else
		echo "Installing ack-grep as ack"
		curl -s http://beyondgrep.com/ack-2.04-single-file > /usr/bin/ack && chmod +x /usr/bin/ack
	fi

	# COMPOSER
	#
	# Install or Update Composer based on current state. Updates are direct from
	# master branch on GitHub repository.
	if composer --version | grep -q 'Composer version';
	then
		printf "Updating Composer...\n"
		composer self-update
	else
		printf "Installing Composer...\n"
		curl -sS https://getcomposer.org/installer | php
		chmod +x composer.phar
		mv composer.phar /usr/local/bin/composer
	fi

	# PHPUnit
	#
	# Check that PHPUnit, Mockery, and Hamcrest are all successfully installed. If
	# not, then Composer should be given another shot at it. Versions for these
	# packages are controlled in the `/srv/config/phpunit-composer.json` file.
	if [ ! -d /usr/local/src/vvv-phpunit ]
	then
		printf "Installing PHPUnit, Hamcrest and Mockery...\n"
		mkdir -p /usr/local/src/vvv-phpunit
		cp /srv/config/phpunit-composer.json /usr/local/src/vvv-phpunit/composer.json
		sh -c "cd /usr/local/src/vvv-phpunit && composer install"
	else
		cd /usr/local/src/vvv-phpunit
		if composer show -i | grep -q 'mockery' ; then echo 'Mockery installed' ; else vvvphpunit_update=1;fi
		if composer show -i | grep -q 'phpunit' ; then echo 'PHPUnit installed' ; else vvvphpunit_update=1;fi
		if composer show -i | grep -q 'hamcrest'; then echo 'Hamcrest installed'; else vvvphpunit_update=1;fi
		cd ~/
	fi

	if [ "$vvvphpunit_update" = 1 ]
	then
		printf "Update PHPUnit, Hamcrest and Mockery...\n"
		cp /srv/config/phpunit-composer.json /usr/local/src/vvv-phpunit/composer.json
		sh -c "cd /usr/local/src/vvv-phpunit && composer update"
	fi
else
	printf "\nNo network connection available, skipping package installation"
fi

# Configuration for nginx
if [ ! -e /etc/nginx/server.key ]; then
	echo "Generate Nginx server private key..."
	vvvgenrsa=`openssl genrsa -out /etc/nginx/server.key 2048 2>&1`
	echo $vvvgenrsa
fi
if [ ! -e /etc/nginx/server.csr ]; then
	echo "Generate Certificate Signing Request (CSR)..."
	openssl req -new -batch -key /etc/nginx/server.key -out /etc/nginx/server.csr
fi
if [ ! -e /etc/nginx/server.crt ]; then
	echo "Sign the certificate using the above private key and CSR..."
	vvvsigncert=`openssl x509 -req -days 365 -in /etc/nginx/server.csr -signkey /etc/nginx/server.key -out /etc/nginx/server.crt 2>&1`
	echo $vvvsigncert
fi

## TODO: get node.js and Grunt installed and working.
## The scripts below "theoretically" install and set them up.
## These are requested as part of the new WordPress development build process http://make.wordpress.org/core/2013/08/06/a-new-frontier-for-core-development/
# # Download & Unpack Node.js - v. 0.10.15
# echo 'Download Node.js - v. 0.10.15'
# mkdir /tmp/node-install
# cd /tmp/node-install
# wget http://nodejs.org/dist/v0.10.15/node-v0.10.15.pkg
# tar -zxf node-v0.10.15.tar.gz
# echo 'Node.js download & unpack completed'
 
# # Install Node.js
# echo 'Install Node.js'
# cd node-v0.10.15
# ./configure && make && make install
# echo 'Node.js install completed'
 
# # Install Node Package Manager
# echo 'Install Node Package Manager'
# curl http://npmjs.org/install.sh | sudo sh
# echo 'NPM install completed'

# # Setting up Grunt - this is a temporary step to pull in code will eventually live inside of the develop repository
# grunt setup



# SYMLINK HOST FILES
printf "\nSetup configuration file links...\n"

ln -sf /srv/config/nginx-config/nginx.conf /etc/nginx/nginx.conf | echo " * /srv/config/nginx-config/nginx.conf -> /etc/nginx/nginx.conf"
ln -sf /srv/config/nginx-config/nginx-wp-common.conf /etc/nginx/nginx-wp-common.conf | echo " * /srv/config/nginx-config/nginx-wp-common.conf -> /etc/nginx/nginx-wp-common.conf"

# Configuration for php5-fpm
ln -sf /srv/config/php5-fpm-config/www.conf /etc/php5/fpm/pool.d/www.conf | echo " * /srv/config/php5-fpm-config/www.conf -> /etc/php5/fpm/pool.d/www.conf"

# Provide additional directives for PHP in a custom ini file
ln -sf /srv/config/php5-fpm-config/php-custom.ini /etc/php5/fpm/conf.d/php-custom.ini | echo " * /srv/config/php5-fpm-config/php-custom.ini -> /etc/php5/fpm/conf.d/php-custom.ini"

# Configuration for Xdebug
ln -sf /srv/config/php5-fpm-config/xdebug.ini /etc/php5/fpm/conf.d/xdebug.ini | echo " * /srv/config/php5-fpm-config/xdebug.ini -> /etc/php5/fpm/conf.d/xdebug.ini"

# Configuration for APC
ln -sf /srv/config/php5-fpm-config/apc.ini /etc/php5/fpm/conf.d/apc.ini | echo " * /srv/config/php5-fpm-config/apc.ini -> /etc/php5/fpm/conf.d/apc.ini"

# Configuration for mysql
cp /srv/config/mysql-config/my.cnf /etc/mysql/my.cnf | echo " * /srv/config/mysql-config/my.cnf -> /etc/mysql/my.cnf"

# Configuration for memcached
ln -sf /srv/config/memcached-config/memcached.conf /etc/memcached.conf | echo " * /srv/config/memcached-config/memcached.conf -> /etc/memcached.conf"

# Custom bash_profile for our vagrant user
ln -sf /srv/config/bash_profile /home/vagrant/.bash_profile | echo " * /srv/config/bash_profile -> /home/vagrant/.bash_profile"

# Custom bash_aliases included by vagrant user's .bashrc
ln -sf /srv/config/bash_aliases /home/vagrant/.bash_aliases | echo " * /srv/config/bash_aleases -> /home/vagrant/.bash_aliases"

# Custom vim configuration via .vimrc
ln -sf /srv/config/vimrc /home/vagrant/.vimrc | echo " * /srv/config/vimrc -> /home/vagrant/.vimrc"

# Capture the current IP address of the virtual machine into a variable that
# can be used when necessary throughout provisioning.
vvv_ip=`ifconfig eth1 | ack "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1`

# RESTART SERVICES
#
# Make sure the services we expect to be running are running.
printf "\nRestart services...\n"
service nginx restart
service php5-fpm restart
service memcached restart

# Disable PHP Xdebug module by default
php5dismod xdebug

# MySQL gives us an error if we restart a non running service, which
# happens after a `vagrant halt`. Check to see if it's running before
# deciding whether to start or restart.
exists_mysql=`service mysql status`
if [ "mysql stop/waiting" == "$exists_mysql" ]
then
	printf "service mysql start"
	service mysql start
else
	printf "service mysql restart"
	service mysql restart
fi

# IMPORT SQL
#
# Create the databases (unique to system) that will be imported with
# the mysqldump files located in database/backups/
if [ -f /srv/database/init-custom.sql ]
then
	mysql -u root -pblank < /srv/database/init-custom.sql | printf "\nInitial custom MySQL scripting...\n"
else
	printf "\nNo custom MySQL scripting found in database/init-custom.sql, skipping...\n"
fi

# Setup MySQL by importing an init file that creates necessary
# users and databases that our vagrant setup relies on.
mysql -u root -pblank < /srv/database/init.sql | echo "Initial MySQL prep...."

# Process each mysqldump SQL file in database/backups to import
# an initial data set for MySQL.
/srv/database/import-sql.sh

if [[ $ping_result == *bytes?from* ]]
then
	# WP-CLI Install
	if [ ! -d /srv/www/wp-cli ]
	then
		printf "\nDownloading wp-cli.....http://wp-cli.org\n"
		git clone git://github.com/wp-cli/wp-cli.git /srv/www/wp-cli
		cd /srv/www/wp-cli
		composer install
	else
		printf "\nUpdating wp-cli....\n"
		cd /srv/www/wp-cli
		git pull --rebase origin master
		composer update
	fi
	# Link `wp` to the `/usr/local/bin` directory
	ln -sf /srv/www/wp-cli/bin/wp /usr/local/bin/wp

	# Webgrind install (for viewing callgrind/cachegrind files produced by
	# xdebug profiler)
	if [ ! -d /srv/www/default/webgrind ]
	then
		printf "\nDownloading webgrind.....https://github.com/jokkedk/webgrind\n"
		git clone git://github.com/jokkedk/webgrind.git /srv/www/default/webgrind

		printf "\nLinking webgrind config file...\n"
		ln -sf /srv/config/webgrind-config.php /srv/www/default/webgrind/config.php | echo " * /srv/config/webgrind-config.php -> /srv/www/default/webgrind/config.php"
	else
		printf "\nUpdating webgrind....\n"
		cd /srv/www/default/webgrind
		git pull --rebase origin master
	fi


	# Checkout, install and configure WordPress development trunk
	if [ ! -d /srv/www/src ]
	then
		printf "Checking out WordPress development trunk.... http://develop.svn.wordpress.org/trunk\n"
		svn co http://develop.svn.wordpress.org/trunk/ /srv/www/
		cd /srv/www/src
		printf "Configuring WordPress development trunk...\n"
		wp core config --dbname=makeblog --dbuser=root --dbpass=blank --quiet --extra-php <<PHP
define( "WP_DEBUG", true );
PHP
		wp core install --url=local.make.dev --quiet --title="Local Make Blog Development Server" --admin_name=admin --admin_email="admin@local.dev" --admin_password="admin"
	else
		printf "Updating WordPress development trunk...\n"
		cd /srv/www/
		svn up --ignore-externals
	fi

	# Checkout makeblog theme
	if [ ! -d /srv/www/src/wp-content/themes/makeblog ]
	then
		printf "Pulling Makeblog from GitHub... https://github.com/Make-Magazine/makeblog.git\n"
		cd /srv/www/src/wp-content/themes/
		mkdir makeblog
		cd makeblog
		git init
		git remote add -f origin https://github.com/Make-Magazine/makeblog.git
		git checkout -f master
	else
		printf "Updating the makeblog theme...\n"
		cd /srv/www/src/wp-content/themes/makeblog/
		git pull origin
	fi

	# Checkout makerfaire theme
	if [ ! -d /srv/www/src/wp-content/themes/makerfaire ]
	then
		printf "Pulling makerfaire from GitHub... https://github.com/Make-Magazine/makerfaire.git\n"
		cd /srv/www/src/wp-content/themes/
		mkdir makerfaire
		cd makerfaire
		git init
		git remote add -f origin https://github.com/Make-Magazine/makerfaire.git
		git checkout -f master
	else
		printf "Updating the makerfaire theme...\n"
		cd /srv/www/src/wp-content/themes/makerfaire/
		git pull origin
	fi

	# Get our VIP plugins - Requires WordPress.com credentials....
	if [ ! -d /srv/www/src/wp-content/themes/vip/plugins ]
	then
		printf "\n************************************************************************************************************\n"
		printf "**************                                                                                  **************\n"
		printf "**************   VIP Plugins NOT FOUND! Please manually add these files to wp-content/themes/   **************\n"
		printf "**************                                                                                  **************\n"
		printf "**************************************************************************************************************\n\n"

	else
		printf "VIP Plugins already setup.\n"
	fi

	# Get the Developer plugin
	if [ ! -d /srv/www/src/wp-content/plugins/developer ]
	then
		printf "Checking out the Developer plugin... http://wordpress.org/plugins/developer/trunk/\n"
		svn co http://plugins.svn.wordpress.org/developer/trunk/ /srv/www/src/wp-content/plugins/developer/
	else
		printf "Updating the Developer plugin... (trunk)\n"
		cd /srv/www/src/wp-content/plugins/developer/
		svn up
	fi

	# Get Debug Bar plugin
	if [ ! -d /srv/www/src/wp-content/plugins/debug-bar ]
	then
		printf "Checking out the Debug Bar plugin... http://plugins.svn.wordpress.org/debug-bar/trunk/\n"
		svn co http://plugins.svn.wordpress.org/debug-bar/trunk/ /srv/www/src/wp-content/plugins/debug-bar/
	else
		printf "Updating the Debug Bar plugin... (trunk)\n"
		cd /srv/www/src/wp-content/plugins/debug-bar/
		svn up
	fi

	# Get Debug Bar Console plugin
	if [ ! -d /srv/www/src/wp-content/plugins/debug-bar-console ]
	then
		printf "Checking out the Debug Bar Console plugin... http://plugins.svn.wordpress.org/debug-bar-console/trunk/\n"
		svn co http://plugins.svn.wordpress.org/debug-bar-console/trunk/ /srv/www/src/wp-content/plugins/debug-bar-console/
	else
		printf "Updating the Debug Bar plugin... (trunk)\n"
		cd /srv/www/src/wp-content/plugins/debug-bar-console/
		svn up
	fi

	# Get VIP Scanner
	if [ ! -d /srv/www/src/wp-content/plugins/vip-scanner ]
	then
		printf "Checking out the VIP Scanner plugin... http://plugins.svn.wordpress.org/vip-scanner/trunk/\n"
		svn co http://plugins.svn.wordpress.org/vip-scanner/trunk/ /srv/www/src/wp-content/plugins/vip-scanner/
	else
		printf "Updating VIP Scanner... (trunk)\n"
		cd /srv/www/src/wp-content/plugins/vip-scanner/
		svn up
	fi

	# Get JetPack
	if [ ! -d /srv/www/src/wp-content/plugins/jetpack ]
	then
		printf "Checking out the JetPack plugin... http://plugins.svn.wordpress.org/jetpack/trunk/\n"
		svn co http://plugins.svn.wordpress.org/jetpack/trunk/ /srv/www/src/wp-content/plugins/jetpack/
	else
		printf "Updating JetPack... (trunk)\n"
		cd /srv/www/src/wp-content/plugins/jetpack/
		svn up
	fi

	# Get MP6
	if [ ! -d /srv/www/src/wp-content/plugins/mp6 ]
	then
		printf "Checking out the MP6 plugin... http://plugins.svn.wordpress.org/mp6/trunk/\n"
		svn co http://plugins.svn.wordpress.org/mp6/trunk/ /srv/www/src/wp-content/plugins/mp6/
	else
		printf "Updating MP6... (trunk)\n"
		cd /srv/www/src/wp-content/plugins/mp6/
		svn up
	fi

	# Download phpMyAdmin 4.0.3
	if [ ! -d /srv/www/default/database-admin ]
	then
		printf "Downloading phpMyAdmin 4.0.3....\n"
		cd /srv/www/default
		wget -q -O phpmyadmin.tar.gz 'http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/4.0.3/phpMyAdmin-4.0.3-english.tar.gz/download#!md5!07dc6ed4d65488661d2581de8d325493'
		tar -xf phpmyadmin.tar.gz
		mv phpMyAdmin-4.0.3-english database-admin
		rm phpmyadmin.tar.gz
	else
		printf "PHPMyAdmin 4.0.3 already installed.\n"
	fi
else
	printf "\nNo network available, skipping network installations. Please connect to the internet to install/update your files."
fi

# Add any custom domains to the virtual machine's hosts file so that it
# is self aware. Enter domains space delimited as shown with the default.
DOMAINS='local.make.dev'
if ! grep -q "$DOMAINS" /etc/hosts
then echo "127.0.0.1 $DOMAINS" >> /etc/hosts
fi

end_seconds=`date +%s`
echo -----------------------------
echo Provisioning complete in `expr $end_seconds - $start_seconds` seconds
if [[ $ping_result == *bytes?from* ]]
then
	echo External network connection established, packages up to date.
else
	echo No external network available. Package installation and maintenance skipped.
fi
echo Server root can be found at http://$DOMAINS, or you may visit http://$vvv_ip
