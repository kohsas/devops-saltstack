
#! /bin/bash

sudo apt-get update
sudo apt-get install python-pip git -y
sudo pip install -I apache-libcloud==0.20.1

# install salt master
curl -L https://bootstrap.saltstack.com | sudo sh -s -- -P -M -N -L -S  


#curl -o salt_install.sh -L http://bootstrap.saltstack.org
#sudo sh salt_install.sh -P -M -N -L

sudo apt-get install salt-cloud
sudo salt-cloud -u


#this is interactive. dont know how to automate this
#sudo gcloud auth login

#this can be automated the rest above is 
sudo gsutil cp gs://salt-stack.appspot.com/salt-master/keys/gle-service-account-private-key.json /tmp/salt.json
gcloud auth activate-service-account 103977633215-compute@developer.gserviceaccount.com --key-file /tmp/salt.json --project salt-stack
sudo rm -f /tmp/salt.json

# this creates a user which is used to ssh into the created
# instance. This creates a 
#sudo gcloud compute ssh saltuser@saltmaster-asia-east1-a 

# instead of the above we can try this
#  put the google compute keys in google storage and copy it to the instance when we have to
sudo mkdir /root/.ssh
sudo gsutil cp gs://salt-stack.appspot.com/salt-master/keys/google* /root/.ssh/
sudo chmod 600 /root/.ssh/google_compute_engine
