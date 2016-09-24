#! /bin/bash
#   Testing information
#         Debian jessie   No Flags/
#         Ubuntu 14.04    No Flags/
#
set -o nounset                              # Treat unset variables as an error

__ScriptVersion="2016.09.24"
__ScriptName="bootstrap_salt_master.sh"


# Bootstrap script truth values
BS_TRUE=1
BS_FALSE=0

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#         NAME:  __usage
#  DESCRIPTION:  Display usage information.
#----------------------------------------------------------------------------------------------------------------------
__usage() {
    cat << EOT

  Usage :  ${__ScriptName} [options]
    By default installs the master, minion, cloud and syndic

  Examples:
    - ${__ScriptName}
    - ${__ScriptName} -S
    - ${__ScriptName} -S -N
    - ${__ScriptName} -N
    - ${__ScriptName} -B salt-stack.appspot.com
    - ${__ScriptName} -S -N -B salt-stack.appspot.com
    - ${__ScriptName} -h
    

  Options:
    -h  Display this message
    -v  Display script version
    -S  Do not install salt-syndic
    -N  Do not install salt-minion
    -B  Pass the google cloud bucket name containing the keys for the saltuser
EOT
}   # ----------  end of function __usage  ---------

_INSTALL_SYNDIC=$BS_TRUE
_INSTALL_MINION=$BS_TRUE
_SCRIPT_OPTIONS="-P -M -L"
_GIT_REPO_NAME="saltstack"
_CLONE_GIT_REPO=$BS_TRUE
_NODE_NAME=`uname -n`
_SALT_CONFIG_DIR='/etc/salt'
_GSTORE_BUCKET='salt-stack.appspot.com'
_TEMP_CONFIG_DIR="null"

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __parse_version_string
#   DESCRIPTION:  Parse version strings ignoring the revision.
#                 MAJOR.MINOR.REVISION becomes MAJOR.MINOR
#   copied from https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh
#----------------------------------------------------------------------------------------------------------------------
__parse_version_string() {
    VERSION_STRING="$1"
    PARSED_VERSION=$(
        echo "$VERSION_STRING" |
        sed -e 's/^/#/' \
            -e 's/^#[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\)\(\.[0-9][0-9]*\).*$/\1/' \
            -e 's/^#[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*$/\1/' \
            -e 's/^#[^0-9]*\([0-9][0-9]*\).*$/\1/' \
            -e 's/^#.*$//'
    )
    echo "$PARSED_VERSION"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __sort_release_files
#   DESCRIPTION:  Custom sort function. Alphabetical or numerical sort is not
#                 enough.
#   copied from https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh
#----------------------------------------------------------------------------------------------------------------------
__sort_release_files() {
    KNOWN_RELEASE_FILES=$(echo "(arch|centos|debian|ubuntu|fedora|redhat|suse|\
        mandrake|mandriva|gentoo|slackware|turbolinux|unitedlinux|lsb|system|\
        oracle|os)(-|_)(release|version)" | sed -r 's:[[:space:]]::g')
    primary_release_files=""
    secondary_release_files=""
    # Sort know VS un-known files first
    for release_file in $(echo "${@}" | sed -r 's:[[:space:]]:\n:g' | sort --unique --ignore-case); do
        match=$(echo "$release_file" | egrep -i "${KNOWN_RELEASE_FILES}")
        if [ "${match}" != "" ]; then
            primary_release_files="${primary_release_files} ${release_file}"
        else
            secondary_release_files="${secondary_release_files} ${release_file}"
        fi
    done

    # Now let us sort by know files importance, max important goes last in the max_prio list
    max_prio="redhat-release centos-release oracle-release"
    for entry in $max_prio; do
        if [ "$(echo "${primary_release_files}" | grep "$entry")" != "" ]; then
            primary_release_files=$(echo "${primary_release_files}" | sed -e "s:\(.*\)\($entry\)\(.*\):\2 \1 \3:g")
        fi
    done
    # Now, least important goes last in the min_prio list
    min_prio="lsb-release"
    for entry in $min_prio; do
        if [ "$(echo "${primary_release_files}" | grep "$entry")" != "" ]; then
            primary_release_files=$(echo "${primary_release_files}" | sed -e "s:\(.*\)\($entry\)\(.*\):\1 \3 \2:g")
        fi
    done

    # Echo the results collapsing multiple white-space into a single white-space
    echo "${primary_release_files} ${secondary_release_files}" | sed -r 's:[[:space:]]+:\n:g'
}


#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __gather_os_info
#   DESCRIPTION:  Discover operating system information
#   copied from https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh
#----------------------------------------------------------------------------------------------------------------------
__gather_os_info() {
    OS_NAME=$(uname -s 2>/dev/null)
    OS_NAME_L=$( echo "$OS_NAME" | tr '[:upper:]' '[:lower:]' )
    OS_VERSION=$(uname -r)
    # shellcheck disable=SC2034
    OS_VERSION_L=$( echo "$OS_VERSION" | tr '[:upper:]' '[:lower:]' )
}
__gather_os_info


#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __gather_linux_system_info
#   DESCRIPTION:  Discover Linux system information
#   copied from https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh
#----------------------------------------------------------------------------------------------------------------------
__gather_linux_system_info() {
    DISTRO_NAME=""
    DISTRO_VERSION=""

    # Let's test if the lsb_release binary is available
    rv=$(lsb_release >/dev/null 2>&1)
    if [ $? -eq 0 ]; then
        DISTRO_NAME=$(lsb_release -si)
        if [ "${DISTRO_NAME}" = "Scientific" ]; then
            DISTRO_NAME="Scientific Linux"
        elif [ "$(echo "$DISTRO_NAME" | grep RedHat)" != "" ]; then
            # Let's convert CamelCase to Camel Case
            DISTRO_NAME=$(__camelcase_split "$DISTRO_NAME")
        elif [ "${DISTRO_NAME}" = "openSUSE project" ]; then
            # lsb_release -si returns "openSUSE project" on openSUSE 12.3
            DISTRO_NAME="opensuse"
        elif [ "${DISTRO_NAME}" = "SUSE LINUX" ]; then
            if [ "$(lsb_release -sd | grep -i opensuse)" != "" ]; then
                # openSUSE 12.2 reports SUSE LINUX on lsb_release -si
                DISTRO_NAME="opensuse"
            else
                # lsb_release -si returns "SUSE LINUX" on SLES 11 SP3
                DISTRO_NAME="suse"
            fi
        elif [ "${DISTRO_NAME}" = "EnterpriseEnterpriseServer" ]; then
            # This the Oracle Linux Enterprise ID before ORACLE LINUX 5 UPDATE 3
            DISTRO_NAME="Oracle Linux"
        elif [ "${DISTRO_NAME}" = "OracleServer" ]; then
            # This the Oracle Linux Server 6.5
            DISTRO_NAME="Oracle Linux"
        elif [ "${DISTRO_NAME}" = "AmazonAMI" ]; then
            DISTRO_NAME="Amazon Linux AMI"
        elif [ "${DISTRO_NAME}" = "Arch" ]; then
            DISTRO_NAME="Arch Linux"
            return
        elif [ "${DISTRO_NAME}" = "Raspbian" ]; then
           DISTRO_NAME="Debian"
        fi
        rv=$(lsb_release -sr)
        [ "${rv}" != "" ] && DISTRO_VERSION=$(__parse_version_string "$rv")
    elif [ -f /etc/lsb-release ]; then
        # We don't have the lsb_release binary, though, we do have the file it parses
        DISTRO_NAME=$(grep DISTRIB_ID /etc/lsb-release | sed -e 's/.*=//')
        rv=$(grep DISTRIB_RELEASE /etc/lsb-release | sed -e 's/.*=//')
        [ "${rv}" != "" ] && DISTRO_VERSION=$(__parse_version_string "$rv")
    fi

    if [ "$DISTRO_NAME" != "" ] && [ "$DISTRO_VERSION" != "" ]; then
        # We already have the distribution name and version
        return
    fi

    # shellcheck disable=SC2035,SC2086
    for rsource in $(__sort_release_files "$(
            cd /etc && /bin/ls *[_-]release *[_-]version 2>/dev/null | env -i sort | \
            sed -e '/^redhat-release$/d' -e '/^lsb-release$/d'; \
            echo redhat-release lsb-release
            )"); do

        [ -L "/etc/${rsource}" ] && continue        # Don't follow symlinks
        [ ! -f "/etc/${rsource}" ] && continue      # Does not exist

        n=$(echo "${rsource}" | sed -e 's/[_-]release$//' -e 's/[_-]version$//')
        shortname=$(echo "${n}" | tr '[:upper:]' '[:lower:]')
        if [ "$shortname" = "debian" ]; then
            rv=$(__derive_debian_numeric_version "$(cat /etc/${rsource})")
        else
            rv=$( (grep VERSION "/etc/${rsource}"; cat "/etc/${rsource}") | grep '[0-9]' | sed -e 'q' )
        fi
        [ "${rv}" = "" ] && [ "$shortname" != "arch" ] && continue  # There's no version information. Continue to next rsource
        v=$(__parse_version_string "$rv")
        case $shortname in
            redhat             )
                if [ "$(egrep 'CentOS' /etc/${rsource})" != "" ]; then
                    n="CentOS"
                elif [ "$(egrep 'Scientific' /etc/${rsource})" != "" ]; then
                    n="Scientific Linux"
                elif [ "$(egrep 'Red Hat Enterprise Linux' /etc/${rsource})" != "" ]; then
                    n="<R>ed <H>at <E>nterprise <L>inux"
                else
                    n="<R>ed <H>at <L>inux"
                fi
                ;;
            arch               ) n="Arch Linux"     ;;
            centos             ) n="CentOS"         ;;
            debian             ) n="Debian"         ;;
            ubuntu             ) n="Ubuntu"         ;;
            fedora             ) n="Fedora"         ;;
            suse               ) n="SUSE"           ;;
            mandrake*|mandriva ) n="Mandriva"       ;;
            gentoo             ) n="Gentoo"         ;;
            slackware          ) n="Slackware"      ;;
            turbolinux         ) n="TurboLinux"     ;;
            unitedlinux        ) n="UnitedLinux"    ;;
            oracle             ) n="Oracle Linux"   ;;
            system             )
                while read -r line; do
                    [ "${n}x" != "systemx" ] && break
                    case "$line" in
                        *Amazon*Linux*AMI*)
                            n="Amazon Linux AMI"
                            break
                    esac
                done < "/etc/${rsource}"
                ;;
            os                 )
                nn="$(__unquote_string "$(grep '^ID=' /etc/os-release | sed -e 's/^ID=\(.*\)$/\1/g')")"
                rv="$(__unquote_string "$(grep '^VERSION_ID=' /etc/os-release | sed -e 's/^VERSION_ID=\(.*\)$/\1/g')")"
                [ "${rv}" != "" ] && v=$(__parse_version_string "$rv") || v=""
                case $(echo "${nn}" | tr '[:upper:]' '[:lower:]') in
                    amzn        )
                        # Amazon AMI's after 2014.09 match here
                        n="Amazon Linux AMI"
                        ;;
                    arch        )
                        n="Arch Linux"
                        v=""  # Arch Linux does not provide a version.
                        ;;
                    debian      )
                        n="Debian"
                        v=$(__derive_debian_numeric_version "$v")
                        ;;
                    sles        )
                        n="SUSE"
                        v="${rv}"
                        ;;
                    *           )
                        n=${nn}
                        ;;
                esac
                ;;
            *                  ) n="${n}"           ;
        esac
        DISTRO_NAME=$n
        DISTRO_VERSION=$v
        break
    done
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __gather_system_info
#   DESCRIPTION:  Discover which system and distribution we are running.
#   copied from https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh
#----------------------------------------------------------------------------------------------------------------------
__gather_system_info() {
    case ${OS_NAME_L} in
        linux )
            __gather_linux_system_info
            ;;
        * )
            echoerror "${OS_NAME} not supported.";
            exit 1
            ;;
    esac

}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#         NAME:  __check_config_dir
#  DESCRIPTION:  Checks the config directory, retrieves URLs if provided.
#----------------------------------------------------------------------------------------------------------------------
__check_config_dir() {
    CC_DIR_NAME="$1"
    CC_DIR_BASE=$(basename "${CC_DIR_NAME}")

    case "$CC_DIR_NAME" in
        http://*|https://*)
            __fetch_url "/tmp/${CC_DIR_BASE}" "${CC_DIR_NAME}"
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
        ftp://*)
            __fetch_url "/tmp/${CC_DIR_BASE}" "${CC_DIR_NAME}"
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
        *)
            if [ ! -e "${CC_DIR_NAME}" ]; then
                echo "null"
                return 0
            fi
            ;;
    esac

    case "$CC_DIR_NAME" in
        *.tgz|*.tar.gz)
            tar -zxf "${CC_DIR_NAME}" -C /tmp
            CC_DIR_BASE=$(basename "${CC_DIR_BASE}" ".tgz")
            CC_DIR_BASE=$(basename "${CC_DIR_BASE}" ".tar.gz")
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
        *.tbz|*.tar.bz2)
            tar -xjf "${CC_DIR_NAME}" -C /tmp
            CC_DIR_BASE=$(basename "${CC_DIR_BASE}" ".tbz")
            CC_DIR_BASE=$(basename "${CC_DIR_BASE}" ".tar.bz2")
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
        *.txz|*.tar.xz)
            tar -xJf "${CC_DIR_NAME}" -C /tmp
            CC_DIR_BASE=$(basename "${CC_DIR_BASE}" ".txz")
            CC_DIR_BASE=$(basename "${CC_DIR_BASE}" ".tar.xz")
            CC_DIR_NAME="/tmp/${CC_DIR_BASE}"
            ;;
    esac

    echo "${CC_DIR_NAME}"
}



#-------------------------------------------
#---  The main function --------------------
#-------------------------------------------

__gather_system_info

while getopts "hvSNB:c:" opt
do
  case "${opt}" in
     h )  __usage; exit 0                                ;;
     v )  echo "$0 -- Version $__ScriptVersion"; exit 0  ;;
     S )  _INSTALL_SYNDIC=$BS_TRUE                       ;;
     N )  _INSTALL_MINION=$BS_FALSE                      ;;
     B )  _GSTORE_BUCKET=$OPTARG                         ;;
     c )  _TEMP_CONFIG_DIR=$(__check_config_dir "$OPTARG")
         # If the configuration directory does not exist, error out
         if [ "$_TEMP_CONFIG_DIR" = "null" ]; then
             echo "Unsupported URI scheme for $OPTARG"
             exit 1
         fi
         if [ ! -d "$_TEMP_CONFIG_DIR" ]; then
             echo "The configuration directory ${_TEMP_CONFIG_DIR} does not exist."
             exit 1
         fi
         ;;
     \?)  echo
         echo "Option does not exist : $OPTARG"
         __usage
         exit 1
         ;;

  esac    # --- end of case ---
done

echo "  Distribution: ${DISTRO_NAME} ${DISTRO_VERSION}"


if [ "$_INSTALL_SYNDIC" -eq $BS_TRUE ]; then
  _SCRIPT_OPTIONS="$_SCRIPT_OPTIONS -S"
fi

if [ "$_INSTALL_MINION" -eq $BS_FALSE ]; then
  _SCRIPT_OPTIONS="$_SCRIPT_OPTIONS -N"
else
  _SCRIPT_OPTIONS="$_SCRIPT_OPTIONS -A $_NODE_NAME"
fi

#dont start the deamons
_SCRIPT_OPTIONS="$_SCRIPT_OPTIONS -X"

if [ "$_TEMP_CONFIG_DIR" != "null" ]; then
  _SCRIPT_OPTIONS="$_SCRIPT_OPTIONS -c $_TEMP_CONFIG_DIR"
fi



#some required packages
sudo apt-get update
sudo apt-get install python-pip git -y
sudo pip install -I apache-libcloud==0.20.1

# install salt master and minion
curl -L https://bootstrap.saltstack.com | sudo sh -s -- $_SCRIPT_OPTIONS

if [ "$_INSTALL_MINION" -eq $BS_TRUE ]; then
  #this node is also a minion.
  #generate the ssh keys and make sure the master has accepted it
  sudo salt-key --gen-keys=$_NODE_NAME
  sudo mkdir -p /etc/salt/pki/minion/
  sudo cp $_NODE_NAME.pub $_SALT_CONFIG_DIR/pki/minion/minion.pub
  sudo mv $_NODE_NAME.pem $_SALT_CONFIG_DIR/pki/minion/minion.pem
  sudo mv $_NODE_NAME.pub $_SALT_CONFIG_DIR/pki/master/minions/$_NODE_NAME
fi

#  put the google compute keys in google storage and copy it to the instance when we have to
_GSTORE_KEY_PATH="gs://$_GSTORE_BUCKET/salt-master/keys"
#[TODO] is this required
sudo mkdir /root/.ssh
sudo gsutil cp $_GSTORE_KEY_PATH/google* /root/.ssh/
sudo chmod 600 /root/.ssh/google_compute_engine
#This is required as gle profiles have this path
sudo cp  /root/.ssh/google_compute_engine $_SALT_CONFIG_DIR/google_compute_engine

#clone the git repository for getting the cloud files so that we can install them
# [TODO] this should change to get this data from some where rather than
# [TODO] did not work on debian the dir existed so it should not have tried to install the repo
if [ -d $_GIT_REPO_NAME ]; then
  if [ !-d "$_GIT_REPO_NAME/.git"]; then
    _GIT_REPO_NAME="$_GIT_REPO_NAME-$RANDOM"
  else
    _CLONE_GIT_REPO=$BS_FALSE
  fi 
fi

#clone the salt configuration repos
if [ "$_CLONE_GIT_REPO" -eq $BS_TRUE ]; then
  sudo apt-get install git -y
  sudo gcloud source repos clone $_GIT_REPO_NAME --project=salt-stack
fi

#update the cloud provide and profiles
cd $_GIT_REPO_NAME && scripts/update_gle_config.sh . $_NODE_NAME $_SALT_CONFIG_DIR

#install the configuration directory
echo -e "id: $_NODE_NAME" | sudo tee -a $_SALT_CONFIG_DIR/minion.d/minion_id.conf

#the -X should not have stared the deamons but for debian it does not work
# so for debian we need to restart the master and minion
#
# [TODO] for the rest we need to start the deamon
#

if [ "$DISTRO_NAME" == "Ubuntu" ]; then
  echo "[INFO] Starting the salt-master and salt-minion"
  sudo service salt-master stop
  sudo service salt-minion stop
  sleep 0.1
  sudo service salt-master start
  sudo service salt-minion start
else
  echo "[INFO] Restarting the salt-master and salt-minion"
  sudo service salt-master restart
  sudo service salt-minion restart
fi