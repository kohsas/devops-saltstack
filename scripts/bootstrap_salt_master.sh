#this is interactive. dont know how to automate this
sudo gcloud init
#this is interactive. dont know how to automate this
sudo gcloud auth login

sudo apt-get update
sudo apt-get install python-pip git -y
sudo pip install -I apache-libcloud==0.20.1
curl -o salt_install.sh -L http://bootstrap.saltstack.org
sudo sh salt_install.sh -P -M -N -L
sudo salt-cloud -u
sudo gcloud compute ssh saltuser@saltmaster-asia-east1-a 

