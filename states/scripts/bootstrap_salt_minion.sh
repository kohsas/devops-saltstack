#! /bin/bash
apt-get update
curl -L https://bootstrap.saltstack.com | sudo sh
echo "master: saltmaster" | sudo tee -a /etc/salt/minion
# disable salt-master  service, if it exists.    
if service --status-all | grep -Fq 'salt-master'; then    
  sudo service salt-master stop    
fi
