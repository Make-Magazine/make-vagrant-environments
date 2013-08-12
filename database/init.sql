# We include default installations of WordPress with this Vagrant setup.
# In order for that to respond properly, default databases should be
# available for use.
CREATE DATABASE IF NOT EXISTS `makeblog`;
GRANT ALL PRIVILEGES ON `makeblog`.* TO 'root'@'localhost' IDENTIFIED BY 'blank';
CREATE DATABASE IF NOT EXISTS `makerfaire`;
GRANT ALL PRIVILEGES ON `makerfaire`.* TO 'root'@'localhost' IDENTIFIED BY 'blank';

# Create an external user with privileges on all databases in mysql so
# that a connection can be made from the local machine without an SSH tunnel
GRANT ALL PRIVILEGES ON *.* TO 'external'@'%' IDENTIFIED BY 'external';
