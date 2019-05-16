#!/bin/bash

# Update and install critical packages
LOG_FILE="/tmp/ec2_bootstrap.sh.log"
echo "Logging to \"$LOG_FILE\" ..."

#
# Hants' Requirements - INSTALLATION OF PYENV - PYTHON VERSION MANAGEMENT TOOL
#
yes | sudo apt-get update;
yes | sudo apt-get install build-essential;
yes | sudo apt-get install zlib1g-dev;
yes | sudo apt-get install libssl-dev libbz2-dev libreadline-dev libsqlite3-dev;
echo "Installing PYENV for simple python version management";
git clone https://github.com/pyenv/pyenv.git ~/.pyenv;
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc;
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc; 
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc;
#IN ORDER FOR THE NEXT TWO COMMANDS TO WOKK 
exec "$SHELL";

#
# Cleanup
#
echo "Cleaning up after our selves ..." | tee -a $LOG_FILE
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
