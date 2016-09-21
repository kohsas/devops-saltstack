#! /bin/bash
# only for google compute cloud
# [TODO] make it generic
# usage: update_gle_config.sh . 'saltmaster-test1' '/etc/salt'
#    
die () {
    echo >&2 "$@"
    echo "[Usage] update_gle_config.sh <directory to cloud files> <salt-master name> <destination base dir>"
    exit 1
}

# [TODO] validate number of parameters
# [TODO] validate base dir and the files required
# [TODO] validate destination and required directories. If they are not present create them
basedir=$1
nodename=$2
destination=$3
providers=$basedir/cloud/cloud.providers.d/gle.conf 
profiles=$basedir/cloud/cloud.profiles.d/gle.conf 
pre_profile=$basedir/cloud/cloud.profiles.d/gle_base.conf 
profiles_tmp="/tmp/tmp_gle.conf"

echo "[INFO] copying $providers"
sudo cp $providers  $destination/cloud.providers.d/

echo "[INFO] copying $profiles"
echo -e "$(cat $pre_profile)minion:\n    master: $nodename\n\n$(cat  $profiles)" > $profiles_tmp
sudo cp $profiles_tmp  $destination/cloud.profiles.d/gle.conf
echo "[INFO] copying service account key"
sudo cp $basedir/cloud/keys/gle-service-account-private-key.json  $destination
sudo chmod 0600 $destination/gle-service-account-private-key.json
echo "[INFO] copying custom master bootstrap script"
sudo cp $basedir/scripts/bootstrap_salt_master.sh $destination/cloud.deploy.d/
