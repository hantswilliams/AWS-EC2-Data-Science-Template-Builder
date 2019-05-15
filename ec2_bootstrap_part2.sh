#!/bin/bash


# Update and install critical packages
LOG_FILE="/tmp/ec2_bootstrap.sh.log"
echo "Logging to \"$LOG_FILE\" ..."


echo 'Continuing off where pyenv installed.....now going to download specific python version';
echo 'Installing Python 3.6.4 and setting as default python'; 
pyenv install 3.6.4;
pyenv global 3.6.4; 
echo 'Done';




#
# Hants' Requirements - INSTALLATION OF VIRTUALENV, GUNICIORN, and FEATHER 
#
echo 'Installing Python virtualenv and gunicorn for deployment of superset';
pip install virtualenv;
pip install gunicorn;
pip install feather-format;
echo 'Done';



#
# Hants' Requirements - INSTALLATION OF MYSQL 
#
echo 'Installing mySQL server -- note, depending on what version you want, will probably want to adjust
this line of code below to specific version';
yes | sudo apt install mysql-server;
#yes | sudo mysql_secure_installation;
yes | sudo apt-get install libmysqlclient-dev;
pip install mysqlclient;   #https://www.shellhacks.com/mysql-run-query-bash-script-linux-command-line/
sudo mysql <<EOF
#ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '46566656';
SET GLOBAL explicit_defaults_for_timestamp=1;   #note - this is for airflow / superset DB configuration 
CREATE DATABASE superset CHARACTER SET utf8 COLLATE utf8_bin; 
CREATE DATABASE airflow CHARACTER SET utf8 COLLATE utf8_unicode_ci; 
CREATE USER 'airflowuser'@'localhost' IDENTIFIED BY '1910Alht4656!';
CREATE USER 'supersetuser'@'localhost' IDENTIFIED BY '1910Alht4656!';
GRANT ALL PRIVILEGES ON airflow.* TO 'airflowuser'@'localhost';
GRANT ALL PRIVILEGES ON superset.* TO 'supersetuser'@'localhost';
FLUSH PRIVILEGES; 
\q; 
EOF
#'note to self: mysql -u root -p';
echo 'mysql jobs finished';




#
# Hants' Requirements - INSTALLATION OF SUPERSET 
#
echo 'Installing superset within a virtualenv - located in home/ubunt/superset';
echo 'After installation with basic sqlite backend, will then convert the sqlite backend to our full-fledge mySQL backend';
yes | sudo apt-get install build-essential libssl-dev libffi-dev libsasl2-dev libldap2-dev;
echo 'now installing specific superset dependencies for mysql backend'
yes | sudo apt-get install libmysqlclient-dev; pip install mysqlclient; 
cd;
mkdir superset; cd superset; python -m venv env;
cd env/bin;
source activate;
cd /home/ubuntu/superset;
pip install superset==0.28.1; 
cd; 
deactivate;
echo "IMPORTANT NOTE 1 - after this script finishes, need to go into the config file for superset,
and change the backend DB connection to SQLALCHEMY_DATABASE_URI = 'mysql://{USER}:{PASSWORD}@localhost/{DBNAME}'
or whatever the username/login should be for the superset mysql connection" 
echo "IMPORTANT NOTE 2 - after updating the config file, will still need to go through and run the 
fabmanager create-admin steps, superset db upgrade, superset init, and then finally the runserver command 
on the appropriate port" 




#
# Hants' Requirements - INSTALLATION OF AIRFLOW  
#
#https://medium.com/@srivathsankr7/apache-airflow-a-practical-guide-5164ff19d18b
echo 'export AIRFLOW_HOME=~/airflow' >> ~/.bashrc;
SLUGIFY_USES_TEXT_UNIDECODE=yes pip install apache-airflow==1.10.0;
airflow initdb
cd airflow;
mkdir dags;
mkdir plugins;
cd;
echo "
then go into $AIRFLOW_HOME/airflow.cfg and change the config file to redirect to appropriate mysql db;
replace sql_alchemy_conn with following, or whwatever DB. name is (https://airflow.apache.org/howto/initialize-database.html)
sql_alchemy_conn = mysql://airflowuser:1910Alht4656!@localhost/airflow
load_examples = False
catchup_by_default = False"
echo "'then reset the db for the changes to take effect'
airflow resetdb;
airflow initdb;
"





# make sure we own ~/.bash_profile after all the 'sudo tee'
sudo chgrp ubuntu ~/.bash_profile
sudo chown ubuntu ~/.bash_profile


#
# Cleanup
#
echo "Cleaning up after our selves ..." | tee -a $LOG_FILE
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*