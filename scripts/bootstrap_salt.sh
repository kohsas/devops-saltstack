#! /bin/bash
apt-get update
curl -L https://bootstrap.saltstack.com | sudo sh
echo "master: saltmaster" | sudo tee -a /etc/salt/minion
