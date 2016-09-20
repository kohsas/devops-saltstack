README
------

For a new project clone this project and run the setup script

-  setup the initial machine
-  fork this project
-  run the setup scripts
-  checkin the generated files
-  run the cloud update script


Setup the initial machine
-------------------------

@google_compute_engine
  These are keys to be used for installing minions
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

