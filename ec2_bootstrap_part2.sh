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



###IMPORTANT NOTE - For Zookeeper, Kafka - Need to probably have at least a instance with 10-15 GB memory, 
###other it will not be able to properly install 

#
# Hants' Requirements - INSTALLATION OF ZOOKEEPER 
#
echo 'Installing ZOOKEEPER, installing java first'
sudo apt-get install default-jre -y #install java 
java -version #check to make sure it has installed properly 
sudo apt-get install zookeeperd -y #installing zookeeper 
sudo systemctl status zookeeper #ensuring that zookeeper is up and running 
sudo systemctl enable zookeeper #enabling zookeeper at startup 


#
# Hants' Requirements - INSTALLATION OF KAFKA
#
echo 'Installing KAFKA'
cd; 
mkdir downloads;
cd downloads;
wget ftp://apache.cs.utah.edu/apache.org/kafka/2.2.0/kafka_2.12-2.2.0.tgz;
sudo mkdir /opt/Kafka ;
sudo tar xvzf kafka_2.12-2.2.0.tgz -C /opt/Kafka;
#Test that it is able to boot up normally, otherwise dont perform two lines below 
#cd /opt/Kafka/kafka_2.12-2.2.0/;
#sudo bin/kafka-server-start.sh config/server.properties; 


#
# Hants' Requirements - INSTALLATION OF JUPYTER NOTEBOOK 
#Note - for production purposes, should look into JUPYTER HUB - this allows a single 
#instance of jupyter that can have multiple users logged into it 
#
cd; 
cd mkdir jupyter;
cd jupyter;
python -m venv env;
cd env/bin;
source activate;
cd /home/ubuntu/jupyter/;
pip install jupyter;
pip install jupyterlab;
###to run jupyter: 
#jupyter notebook
###################
###to run jupyter lab: 
#jupyter lab



##3) Elasticsearch 
#4) Jupiyter Notebook 
#5) Docker 


#################################################################################################################################################################
#################################################################################################################################################################



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
#ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'TEMPPASSWORD';
SET GLOBAL explicit_defaults_for_timestamp=1;   #note - this is for airflow / superset DB configuration 
CREATE DATABASE superset CHARACTER SET utf8 COLLATE utf8_bin; 
CREATE DATABASE airflow CHARACTER SET utf8 COLLATE utf8_unicode_ci; 
CREATE USER 'airflowuser'@'localhost' IDENTIFIED BY 'TEMPPASSWORD!';
CREATE USER 'supersetuser'@'localhost' IDENTIFIED BY 'TEMPPASSWORD!';
GRANT ALL PRIVILEGES ON airflow.* TO 'airflowuser'@'localhost';
GRANT ALL PRIVILEGES ON superset.* TO 'supersetuser'@'localhost';
FLUSH PRIVILEGES; 
\q; 
EOF
#'note to self: mysql -u root -p';
echo 'mysql jobs finished';

#################################################################################################################################################################
#################################################################################################################################################################





#
# Hants' Requirements - INSTALLATION OF SUPERSET 
#
echo 'Installing superset within a virtualenv - located in home/ubunt/superset';
echo 'After installation with basic sqlite backend, will then convert the sqlite backend to our full-fledge mySQL backend';
yes | sudo apt-get install build-essential libssl-dev libffi-dev libsasl2-dev libldap2-dev;
echo 'now installing specific superset dependencies for mysql backend'
cd;
mkdir superset; cd superset; python -m venv env;
cd env/bin;
source activate;
cd /home/ubuntu/superset;
pip install superset==0.28.1; 
cd; 
y | pip uninstall pandas;
y | pip install pandas==0.23.4
pip install sqlalchemy==1.2.18;
yes | sudo apt-get install libmysqlclient-dev; 
pip install mysqlclient; 


echo "IMPORTANT NOTE 1 - after this script finishes, need to go into the config file for superset,
and change the backend DB connection to SQLALCHEMY_DATABASE_URI = to the proper connection"

VAL="'mysql://supersetuser:TEMPPASSWORD!@localhost/superset'";    #note - this includes 'xx' insside of the string; because superset requires them; 
sed -i -e "/SQLALCHEMY_DATABASE_URI =/ s/= .*/= ${VAL//\//\\/}/" /home/ubuntu/superset/env/lib/python3.6/site-packages/superset/config.py;

#check out this potential command for doing the below, but automated: 
echo "loading in user credentials";
#cd /home/ubuntu/superset_test/env/lib/python3.6/site-packages/superset/bin;
fabmanager create-admin --app 'superset' --username 'hants' --firstname 'hants'  --lastname 'williams'  --email 'hantsawilliams@gmail.com' --password '46566656';
superset db upgrade | tee -a $LOG_FILE
superset init | tee -a $LOG_FILE

#superset runserver -d  | tee -a $LOG_FILE. #to run on port 8080

#################################################################################################################################################################
#################################################################################################################################################################









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

echo "then go into $AIRFLOW_HOME/airflow.cfg and change the config file to redirect to appropriate mysql db;
replace sql_alchemy_conn with following, or whwatever DB. name is, and turn off load_examples and catchup by default"

sed -i -e "/load_examples =/ s/= .*/= False/" /home/ubuntu/airflow/airflow.cfg
sed -i -e "/catchup_by_default =/ s/= .*/= False/" /home/ubuntu/airflow/airflow.cfg

varconfigurationairflow="mysql://airflowuser:TEMPPASSWORD!@localhost/airflow"  ##note - this does not include 'xx' quotes insside of the string; because airflow does not require them; 

sed -i -e "/sql_alchemy_conn =/ s/= .*/= ${varconfigurationairflow//\//\\/}/" /home/ubuntu/airflow/airflow.cfg
#https://stackoverflow.com/questions/27787536/how-to-pass-a-variable-containing-slashes-to-sed

echo "'then reset the db for the changes to take effect"
y | airflow resetdb;
y | airflow initdb;


echo "IMPORTANT NOTE FOR AIRFLOW TO FUNCTION - will still need to start via 
airflow scheduler -D;
airflow webserver -D;" | tee -a $LOG_FILE



#################################################################################################################################################################
#################################################################################################################################################################





# make sure we own ~/.bash_profile after all the 'sudo tee'
sudo chgrp ubuntu ~/.bash_profile
sudo chown ubuntu ~/.bash_profile







#
# Cleanup
#
echo "Cleaning up after our selves ..." | tee -a $LOG_FILE
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
