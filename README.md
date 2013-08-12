# Make Vagrant Environments

Make Vagrant Environments is a [Vagrant](http://vagrantup.com) configuration based on [Varying Vagrant Vagrants](https://github.com/10up/varying-vagrant-vagrants) which is focused on [WordPress](http://wordpress.org) development.

* **Verions**: 0.1-working
* **Contributors**: [@colegeissinger](https://github.com/colegeissinger), [@whyisjake](https://github.com/whyisjake)
* **Contributing**: Contributions are more than welcome. Please submit pull requests against the [master branch](https://github.com/colegeissinger/make-vagrant-environments). Thanks!

## Overview

### The Purpose of Make Vagrant Environments

The primary goal of MVE is to simplify development at Maker Media and accurately test against WordPress VIP locally. For a while we used MAMP and personally updating our local developments individually, but things are becoming more complicated as the team grows. We have decided to move to using Vagrant, a way to create virtual machines for testing and developing in an enviroment just like our production server.

This forked copy of Varying Vagrant Vagrants is modified to support Maker Media's web dev team by loading an environment for both Mage Magazine and Maker Faire, load both themes and also create a database with standard content. Also, this version is syncing with develop.svn.wordpress.org, which is the new and preferred development area for WordPress.

In a future version, this MVE will install and use Node.js and Grunt as recommended with the new WordPress development build process which incorporates Unit Testing and i18n translations.

## Getting Started

### What is Vagrant?

[Vagrant](http://vagrantup.com) is a "tool for building and distributing development environments". It works with virtualization software such as [VirtualBox](http://virtualbox.org) to provide a virtual machine that is sandboxed away from your local environment.

### The First Vagrant Up

1. Start with any operating system.
1. Install [VirtualBox 4.2.16](https://www.virtualbox.org/wiki/Downloads)
    * MVE (and Vagrant) has been tested with this version. If a newer version appears on the downloads page and you don't feel like being a guinea pig, check out the [older downloads](https://www.virtualbox.org/wiki/Download_Old_Builds_4_2) page and download the 4.2.16 release.
1. Install [Vagrant 1.2.5](http://downloads.vagrantup.com/tags/v1.2.5)
    * `vagrant` will now be available as a command in the terminal, try it out.
1. Clone the Make Vagrant Environments repository into a local directory. At Make, we prefer to work off the "~/Sites" directory in OS X.
    * `git clone git://github.com/colegeissinger/make-vagrant-environments.git`
    * OR download and extract the repository master [zip file](https://github.com/colegeissinger/make-vagrant-environments/archive/master.zip)
1. Change into the new directory
    * `cd ~/Sites`
1. Start the Vagrant environment
    * `vagrant up` - *omg magic happens*
    * Be patient, this could take a while, especially on the first run.
1. Add a record to your local machine's hosts file
    * `192.168.50.4  local.make.dev`
    * On -nix systems you can use: (note that location of host file after the >> may vary) `sudo sh -c 'echo "192.168.50.4 local.make.dev" >> /private/etc/hosts'`
1. Visit `http://local.make.dev/` in your browser for Makezine.com. By default we load the Make Magazine theme and database.

### What Did That Do?

The first time you run `vagrant up`, a pre-packaged virtual machine box is downloaded to your local machine and cached for future use. The file used by Make Vagrant Environments contains an Ubuntu 12.04 installation (Precise release) and is about 280MB.

After this box is downloaded, it begins to boot as a sandboxed virtual machine using VirtualBox. When ready, it runs the provisioning script also provided with this repository. This initiates the download and installation of around 88MB of packages on the new virtual machine.

The time for all of this to happen depends a lot on the speed of your Internet connection. If you are on a fast cable connection, it will more than likely only take several minutes.

On future runs of `vagrant up`, the pre-packaged box will already be cached on your machine and Vagrant will only need to deal with provisioning. If the machine has been destroyed with `vagrant destroy`, it will need to download the full 88MB of packages to install. If the vagrant has been powered off with `vagrant halt`, the provisioning script will run but will not need to download anything.

### Now What?

Now that we have MVE running, let's talk about changing databases. Instead of having multiple copies of WordPress setup, we use one set of core files and multiple databases. MVE includes a shell script that you can use to automate switching databases. You can find this in the root of the repository called `switch-make-database.sh`. Move this file into the bin folder in your user directory. Doing this will make this file globally accessable in any directory. In some instances this directory does not exist, go ahead and create it.

To create a bin directory in your user directory, in terminal type in `cd ~; mkdir bin`. Now you can move `switch-make-database.sh` into that bin folder.

#### Using switch-make-database.sh

1. Open Terminal and type `switch-make-database.sh makeblog` or `switch-make-database.sh makerfaire`

Fancy, yeah?

But wait, that's not all!

* Access the server with `vagrant ssh` from your `~/Sites` directory. You can do pretty much anything you would do with a standard Ubuntu installation on a full server.
    * If you are on a Windows PC, you may need to install additional software for this to work seamlessly. A terminal program such as [Putty](www.chiark.greenend.org.uk/~sgtatham/putty/download.html) will provide access immediately.
* Destroy the box and start from scratch with `vagrant destroy`
    * As explained before, the initial 280MB box file will be cached on your machine. the next `vagrant up` command will initiate the complete provisioning process again.
* Power off the box with `vagrant halt` or suspend it with `vagrant suspend`. If you suspend it, you can bring it back quickly with `vagrant resume`, if you halt it, you can bring it back with `vagrant up`.
* Other Notes
    * The network configuration picks an IP of 192.168.50.4. This works if you are *not* on the 192.168.50.x sub domain, it could cause conflicts on your existing network if you *are* on a 192.168.50.x sub domain already. You can configure any IP address in the `Vagrantfile` and it will be used on the next `vagrant up`
    * If you require any custom SQL commands to run when the virtual machine boots, move `database/init-custom.sql.sample` to `database/init-custom.sql` and edit it to add whichever `CREATE DATABASE` and `GRANT ALL PRIVILEGES` statements you want to run on startup to prepare mysql for SQL imports (see next bullet).
    * Have any SQL files that should be imported in the `database/backups/` directory and named as `db_name.sql`. The `import-sql.sh` script will run automatically when the VM is built and import these databases into the new mysql install as long as the proper databases have already been created via the previous step's SQL.
    * Check out the example nginx configurations in `config/nginx-config/sites` and create any other site specific configs you think should be available on server start. The web directory is `/srv/www/` and default configs are provided for basic WordPress 3.5.1 and trunk setups.
    * Once a database is imported on the initial `vagrant up`, it will persist on the local machine a mapped mysql data directory.
    * Other stuff. Familiarize and all that.

### Credentials and Such

#### Make Dev URL
* URL: `http://local.make.dev`
* DB Name: `makeblog` or `makerfaire` (see `using switch-make-database.sh` for switching databases)
* DB User: `root`
* DB Pass: `blank`
* Admin User: `admin`
* Admin Pass: `admin`

#### MySQL via [phpMyAdmin](http://www.phpmyadmin.net/home_page/index.php)
* URL: `http://local.default.dev/phpmysql`
* User: `root`
* Pass: `blank`

#### MySQL Locally ([Sequal Pro](http://www.sequelpro.com/) (OS X), [HeidiSQL](http://www.heidisql.com/) (Windows), or [MySQL Workbench](http://dev.mysql.com/downloads/tools/workbench/) (Cross-platform)
* SSH Tunnel
* SSH Host: `local.make.dev` (alternativaly you can input the IP address `192.168.50.4`)
* SSH User: `vagrant`
* SSH Pass: `vagrant`
* SSH Port: Leave blank or default
* MySQL Host: 127.0.0.1
* MySQL User: `root`
* MySQL Pass: `blank`
* Database & Prot: Leave blank or default

### What do you get?

A bunch of stuff!

1. [Ubuntu](http://ubuntu.com) 12.04 LTS (Precise Pangolin)
1. [nginx](http://nginx.org) 1.4.2
1. [mysql](http://mysql.com) 5.5.31
1. [php-fpm](http://php-fpm.org) 5.4.17
1. [memcached](http://memcached.org/) 1.4.13
1. PHP [memcache extension](http://pecl.php.net/package/memcache/3.0.6) 3.0.6
1. [xdebug](http://xdebug.org/) 2.2.1
1. [PHPUnit](http://pear.phpunit.de/) 3.7.21
1. [ack-grep](http://beyondgrep.com/) 2.04
1. [git](http://git-scm.com) 1.8.3.4
1. [subversion](http://subversion.apache.org/) 1.7.9
1. [ngrep](http://ngrep.sourceforge.net/usage.html)
1. [dos2unix](http://dos2unix.sourceforge.net/)
1. [WordPress Development trunk](http://develop.svn.wordpress.org)
1. [WP-CLI](http://wp-cli.org)
1. [Composer](https://github.com/composer/composer)
1. [phpMemcachedAdmin](https://code.google.com/p/phpmemcacheadmin/) 1.2.2 BETA
1. [phpMyAdmin](http://www.phpmyadmin.net) 4.0.3
1. [Webgrind](https://github.com/jokkedk/webgrind) 1.1

### Need/want to get more familiar with Vagrant, Node.js or Grunt?

#### Vagrant
* [Vagrant (Official Website)](http://www.vagrantup.com/)
* [Vagrant: What, Why, and How (Nettuts+ Tutorial)](http://net.tutsplus.com/tutorials/php/vagrant-what-why-and-how/)
* [Varying Vagrant Vagrants (GitHub Repo MVE is forked from)](https://github.com/10up/varying-vagrant-vagrants)

#### Node.js
* [Node.js (Official Website)](http://nodejs.org/)
* [The Node Beginner Book (E-Book)](http://www.nodebeginner.org/)
* [Node.js for Beginners (Nettus+ Tutorial)](http://net.tutsplus.com/tutorials/javascript-ajax/node-js-for-beginners/)

#### Grunt
* [Grunt (Official Website)](http://gruntjs.com/)
* [Meet Grunt: The Build Tool for JavaScript (Nettuts+ Tutorial)](http://net.tutsplus.com/tutorials/javascript-ajax/meeting-grunt-the-build-tool-for-javascript/)
* [A Tutorial for Getting Started with Grunt (Online Tutorials)](http://www.justinmccandless.com/blog/A%20Tutorial%20for%20Getting%20Started%20with%20Grunt)
