#!/bin/bash

######################################################
# Author: Ryan H. Johnston
# ID: ide709
# Department: Tech Cafe

# Note: run this script as sudoer
# Ex. sudo ./utsa_gp_install.sh
#
# Notes:
# Creating certs for the official protect .deb and .rpm package is not completed
# It will be updated to include the official packages soon
# For now, the open-source globalprotect-openconnect package works just as well
# It uses the official globalprotect service on the openconnect VPN software
# This makes it possible to use the service on all linux distributions
# It can even be built from source
# The official repository can be found here: https://github.com/yuezk/GlobalProtect-openconnect
######################################################


#  _   _ _____ ____    _    
# | | | |_   _/ ___|  / \   
# | | | | | | \___ \ / _ \  
# | |_| | | |  ___) / ___ \ 
#  \___/  |_| |____/_/   \_\


# Global Protect VPN info after installation
gpclient_info() 
{
    inst=$1
    arch=$2
    printf "\n-----------------------------------------------------------------------\n
    Global Protect VPN for UTSA is installed\n
    To uninstall, simply type: $inst globalprotect$arch\n
    Run the VPN by typing: gpclient\n
    Portal Address: vpn.utsa.edu
    \n-----------------------------------------------------------------------\n\n"
}

# Must be run as root
if [ "$EUID" -ne 0 ]; then
    printf "ERROR: Please run this script as root.\n"
    exit 1
fi

# If installed using globalprotect-openconnect package
verify-cert() 
{
    PIN="9qJPX5obul5UwvU/73D3ZmK6ewOu9upm2ga1NFKRiXs="
    GP_CONF=/etc/gpservice/gp.conf
    if [ -f $GP_CONF ]; then
        printf "$GP_CONF exists, appending cert pin\n"
        echo "[vpn.utsa.edu]" >> $GP_CONF
        echo "openconnect-args=--servercert pin-sha256:$PIN" >> $GP_CONF
    else
        printf "Creating $GP_CONF\n"
        touch /etc/gpservice/gp.conf
        echo "[vpn.utsa.edu]" >> $GP_CONF
        echo "openconnect-args=--servercert pin-sha256:$PIN" >> $GP_CONF
    fi
}

# Run os-release file to get environment variables
source /etc/os-release
kernel_ver=$(uname -r)
open_msg="\n-----------------------------------------------------------------------\n
Installing Global Protect VPN for UTSA on $ID
\n-----------------------------------------------------------------------\n\n"

# Check the version of the distro if ubuntu, rhel, or centos
if [ $ID == "ubuntu" ]; then
    linux_ver=${VERSION_ID:0:2}
elif [[ $ID == "rhel" || $ID == "centos" ]]; then
    linux_ver=${VERSION_ID:0:1}
fi

# Install the VPN based on the ID variable
case $ID in
    ubuntu)
        printf "$open_msg"

        apt_output=$(apt list --installed | grep globalprotect)

        if [[ $apt_output == *"globalprotect"* ]]; 
        then
            printf "\nOld version of Global Protect VPN detected, uninstalling...\n\n"
            apt-get purge *globalprotect* -y
        fi

        case $linux_ver in
            14)
                ;&
            16)
                ;&
            18)
                apt-get install ./GlobalProtect_deb-*.deb
                gpclient_info "sudo apt-get remove"
                exit 0
                ;;
            *)
                apt-get install ./GlobalProtect_focal_deb-*.deb
                gpclient_info "sudo apt-get remove"
                exit 0
                ;;
        esac
        ;;
    fedora)
        printf "$open_msg"

        yum_output=$(yum list installed | grep globalprotect)

        if [[ $yum_output == *"globalprotect.x86"* ]];
        then
            printf "\nOld version of Global Protect VPN detected, uninstalling...\n\n"
            yum -y remove globalprotect 
        fi

        dnf install GlobalProtect_rpm-*.rpm
        gpclient_info "sudo dnf remove"
        exit 0
        ;;
    rhel)
        ;&
    arch)
        printf "$open_msg"

        pacman_output=$(pacman -Qi globalprotect-openconnect)

        if [[ $pacman_output == *": globalprotect-openconnect"* ]];
        then
            printf "\nOld version of Global Protect detected VPN, uninstalling...\n\n"
            pacman -Rs globalprotect-openconnect --noconfirm
        fi

        pacman -S globalprotect-openconnect --noconfirm
        verify-cert
        gpclient_info "sudo pacman -R" "-openconnect"
        exit 0
        ;;
    *)
        printf "\nERROR: Linux Distrubtion not found, installing for Debian.\n\n"
        ;;
esac

# If not Ubuntu but is a debian distro
if [[ $ID_LIKE == "ubuntu debian" ]];
then
    printf "$open_msg"
    apt-get install globalprotect-openconnect -y	
    verify-cert	
    gpclient_info "sudo apt-get remove" "-openconnect"
    exit 0
else
    printf "\nERROR: Linux Distribution not found.\n\n"
    exit 1
fi
