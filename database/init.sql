# We include makeblog and makerfaire themes. We'll need a database to get up and running

# Setup the makeblog database
CREATE DATABASE IF NOT EXISTS `makeblog`;
GRANT ALL PRIVILEGES ON `makeblog`.* TO 'root'@'localhost' IDENTIFIED BY 'blank';
CREATE DATABASE IF NOT EXISTS `makerfaire`;
GRANT ALL PRIVILEGES ON `makerfaire`.* TO 'root'@'localhost' IDENTIFIED BY 'blank';

# Create an external user with privileges on all databases in mysql so
# that a connection can be made from the local machine without an SSH tunnel
GRANT ALL PRIVILEGES ON *.* TO 'external'@'%' IDENTIFIED BY 'external';
