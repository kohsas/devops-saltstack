#! /bin/bash

RC="\033[1;31m"
GC="\033[1;32m"
BC="\033[1;34m"
YC="\033[1;33m"
EC="\033[0m"

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  echoerr
#   DESCRIPTION:  Echo errors to stderr.
#----------------------------------------------------------------------------------------------------------------------
echoerror() {
    printf "${RC} * ERROR${EC}: %s\n" "$@" 1>&2;
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  echoinfo
#   DESCRIPTION:  Echo information to stdout.
#----------------------------------------------------------------------------------------------------------------------
echoinfo() {
    printf "${GC} *  INFO${EC}: %s\n" "$@";
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  echowarn
#   DESCRIPTION:  Echo warning informations to stdout.
#----------------------------------------------------------------------------------------------------------------------
echowarn() {
    printf "${YC} *  WARN${EC}: %s\n" "$@";
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  echodebug
#   DESCRIPTION:  Echo debug information to stdout.
#----------------------------------------------------------------------------------------------------------------------
echodebug() {
  printf "${BC} * DEBUG${EC}: %s\n" "$@";
}

parse_config_file_for_item() {
    awk -v section="$2" -v variable="$3" '
      $0 == "[" section "]" { in_section = 1; next }
      in_section && $1 == variable {
          $1=""
          $2=""
          sub(/^[[:space:]]+/, "")
          print
          exit 
      }
      in_section && $1 == "" {
          # we are at a blank line without finding the var in the section
          print "not found" > "/dev/stderr"
          exit 1
      }
  ' "$1"
  
}

trim_leading_blank() {
  _ARG=$1
  echo $_ARG
 "echo "$_ARG"| sed -e 's/^[[:space:]]*//'"
}

parser_config_file() {
  _CONFIG_FILE=$1
  echodebug "Using config file $_CONFIG_FILE"
  _GIT_EMAIL="$(echo -e $( parse_config_file_for_item $_CONFIG_FILE git email ) | sed -e 's/^[[:space:]]*//')"
  _GIT_NAME="$(echo -e $( parse_config_file_for_item $_CONFIG_FILE git name) | sed -e 's/^[[:space:]]*//')"
  _GCLOUD_SERVICE="$(echo -e $( parse_config_file_for_item $_CONFIG_FILE gcloud service ) | sed -e 's/^[[:space:]]*//')"
  _GCLOUD_PROJECT="$(echo -e $( parse_config_file_for_item $_CONFIG_FILE gcloud project ) | sed -e 's/^[[:space:]]*//')"
  _GCLOUD_KEY="$(echo -e $( parse_config_file_for_item $_CONFIG_FILE gcloud key )| sed -e 's/^[[:space:]]*//')"
}

print_config(){
  echodebug "GIT EMAIL:$_GIT_EMAIL"
  echodebug "GIT NAME:$_GIT_NAME"
  echodebug "GCLOUD SERVICE:$_GCLOUD_SERVICE"
  echodebug "GCLOUD PROJECT :$_GCLOUD_PROJECT"
  echodebug "GCLOUD KEY :$_GCLOUD_KEY"
}

authenticate_gcloud_service_account() {
  #adjust file name
  _GCLOUD_KEY="/tmp/config/$_GCLOUD_KEY"
  if  ([ "$_GCLOUD_SERVICE" != "" ] && [ "$_GCLOUD_PROJECT" != "" ] && [ -f "$_GCLOUD_KEY" ]); then
    echoinfo "All required data for Google Compute Cloud Autentication found"
    echodebug "SERVICE: $_GCLOUD_SERVICE"
    echodebug "PROJECT: $_GCLOUD_PROJECT"
    gcloud auth activate-service-account $_GCLOUD_SERVICE --key-file $_GCLOUD_KEY  --project $_GCLOUD_PROJECT
  else
    echoerror "gcloud service authentication failed $_GCLOUD_KEY"
    ls /tmp/config
  fi
}

git_configuration() {
  if [ "$_GIT_EMAIL" != "" ]; then
    git config --global user.email $_GIT_EMAIL
  fi
  if [ "$_GIT_NAME" != "" ]; then
    git config --global user.name $_GIT_NAME
  fi
}
#the main execution

parser_config_file $1
print_config
authenticate_gcloud_service_account
git_configuration
