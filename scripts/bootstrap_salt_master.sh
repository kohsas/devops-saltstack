#! /bin/bash

# [TODO] command line parameters for minion required

#get the node name
nodename=`uname -n`

#some required packages
sudo apt-get update
sudo apt-get install python-pip git -y
sudo pip install -I apache-libcloud==0.20.1

# install salt master and minion
curl -L https://bootstrap.saltstack.com | sudo sh -s -- -P -M -L -S  -A $nodename -X

#this node is also a minion.
#generate the ssh keys and make sure the master has accepted it
sudo salt-key --gen-keys=$nodename
sudo mkdir -p /etc/salt/pki/minion/
sudo cp $nodename.pub /etc/salt/pki/minion/minion.pub
sudo mv $nodename.pem /etc/salt/pki/minion/minion.pem
sudo mv $nodename.pub /etc/salt/pki/master/minions/$nodename


sudo apt-get install salt-cloud
sudo salt-cloud -u
#  put the google compute keys in google storage and copy it to the instance when we have to
sudo mkdir /root/.ssh
sudo gsutil cp gs://salt-stack.appspot.com/salt-master/keys/google* /root/.ssh/
sudo chmod 600 /root/.ssh/google_compute_engine

#clone the git repository for getting the cloud files so that we can install them
# [TODO] this should change to get this data from some where rather than
if [ ! -d "saltstack" ]; then
  gcloud source repos clone saltstack --project=salt-stack
fi
cd saltstack && scripts/update_gle_config.sh . $nodename '/etc/salt'

echo -e "id: $nodename" | sudo tee -a /etc/salt/minion.d/minion_id.conf

#the -X should not have stared the deamons but for debian it does not work
# so for debian we need to restart the master and minion
#
# [TODO] for the rest we need to start the deamon
#
echo "[INFO] Restarting the salt-master and salt-minion"
sudo service salt-master restart
sudo service salt-minion restart