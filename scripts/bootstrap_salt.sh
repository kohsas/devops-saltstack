#! /bin/bash
apt-get update
curl -L https://bootstrap.saltstack.com | sudo sh
sudo echo "10.140.0.2 salt" >> /etc/hosts
