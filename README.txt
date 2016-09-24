README
------

New project
------------
For a new project clone this project and run the setup script

1)  Create a new machine 
2)  fork this project
      >gcloud source repos clone saltstack --project=salt-stack
3)  run the setup scripts
      >./saltstack/scripts/bootstrap_salt_master.sh

This will create a salt-master with all the required





@google_compute_engine
  These keys are used for installing minions (using salt-cloud)
  1) Create ssh account [sudo gcloud compute ssh saltuser@saltmaster-asia-east1-a ]
  2) create the directory in google storage bucket (gs://<bucket>/salt-master/keys
  s) copy the google_compute_engine and google_compute_engine.pub to the google storage

Cloud Providers
---------------
*Google Compute Cloud*
   [TODO] create a script to generate the google cloud Providers




Reference
---------
[1] https://hub.docker.com/r/google/cloud-sdk/

