#! /bin/bash

die () {
    echo >&2 "$@"
    echo "[Usage] update_gle_config.sh <directory to cloud files>"
    exit 1
}

sudo cp cloud/cloud.providers.d/gle.conf  /etc/salt/cloud.providers.d/
sudo cp cloud/cloud.profiles.d/gle.conf  /etc/salt/cloud.profiles.d/
sudo cp cloud/keys/gle-service-account-private-key.json  /etc/salt/
sudo chmod 0600 '/etc/salt/gle-service-account-private-key.json'
