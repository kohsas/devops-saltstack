README for my learning of salt



Installing Salt on Ubuntu
-------------------------
sudo add-apt-repository ppa:saltstack/salt
sudo add-apt-repository ppa:saltstack/salt2015-5
sudo apt-get install python-software-properties
sudo apt-get install software-properties-common
echo deb http://ppa.launchpad.net/saltstack/salt/ubuntu `lsb_release -sc` main | sudo tee /etc/apt/sources.list.d/saltstack.list
wget -q -O- "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x4759FA960E27C0A6" | sudo apt-key add -
sudo apt-get update
sudo apt-get install salt-api salt-cloud salt-minion salt-ssh salt-syndic
