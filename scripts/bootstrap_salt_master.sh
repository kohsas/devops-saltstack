
#! /bin/bash

nodename=`uname -n`
sudo apt-get update
sudo apt-get install python-pip git -y
sudo pip install -I apache-libcloud==0.20.1
# install salt master
curl -L https://bootstrap.saltstack.com | sudo sh -s -- -P -M -L -S  
sudo apt-get install salt-cloud
sudo salt-cloud -u
#  put the google compute keys in google storage and copy it to the instance when we have to
sudo mkdir /root/.ssh
sudo gsutil cp gs://salt-stack.appspot.com/salt-master/keys/google* /root/.ssh/
sudo chmod 600 /root/.ssh/google_compute_engine
#clone the git repository for getting the cloud files so that we can install them
# [TODO] this should change to get this data from some where rather than
gcloud source repos clone saltstack --project=salt-stack
cd saltstack && scripts/update_gle_config.sh . $nodename '/etc/salt'
