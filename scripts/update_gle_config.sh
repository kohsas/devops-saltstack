#! /bin/bash

die () {
    echo >&2 "$@"
    echo "[Usage] update_gle_config.sh <directory to cloud files>"
    exit 1
}

nodename=`uname -n`
basedir=$1
providers=$basedir/cloud/cloud.providers.d/gle.conf 
profiles=$basedir/cloud/cloud.profiles.d/gle.conf 
pre_profile=$basedir/cloud/cloud.profiles.d/gle_base.conf 
profiles_tmp="/tmp/tmp_gle.conf"
echo "[INFO] copying $providers"
sudo cp $providers  /etc/salt/cloud.providers.d/

echo "[INFO] copying $profiles"
echo -e "$(cat $pre_profile)minion:\n    master: $nodename\n\n$(cat  $profiles)" > $profiles_tmp
sudo cp $profiles_tmp  /etc/salt/cloud.profiles.d/gle.conf
echo "[INFO] copying service account key"
sudo cp $basedir/cloud/keys/gle-service-account-private-key.json  /etc/salt/
sudo chmod 0600 '/etc/salt/gle-service-account-private-key.json'


