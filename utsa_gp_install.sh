#!/bin/bash

######################################################
# Author: Ryan H. Johnston
# ID: ide709
# Department: UTS

# Note: run this script as sudoer
# Ex. sudo ./install.sh
######################################################

#  _   _ _____ ____    _    
# | | | |_   _/ ___|  / \   
# | | | | | | \___ \ / _ \  
# | |_| | | |  ___) / ___ \ 
#  \___/  |_| |____/_/   \_\

# Program: CLI only
# Determine the Linux distro and version

# Was originally supposed to ask the user if they wanted to run the program
# It's simply not possible
# It's best to make this function just an info dump
function gpclient-info {
    printf "\n-----------------------------------------------------------------------\n
              Global Protect VPN for UTSA is installed\n
              Run the VPN by typing: gpclient\n
              Portal Address: vpn-pa.it.utsa.edu
            \n-----------------------------------------------------------------------\n\n"
}

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
                gpclient-info
                exit
                ;;
            *)
                apt-get install ./GlobalProtect_focal_deb-*.deb
                gpclient-info
                exit
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
        gpclient-info
        exit
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
        gpclient-info
        exit
        ;;
    *)
        printf "\nERROR: Linux Distrubtion not found, installing for Debian.\n\n"
        ;;
esac

if [[ $ID_LIKE == "ubuntu debian" ]];
then
        printf "$open_msg"
        repo_add=$(add-apt-repository ppa:yuezk/globalprotect-openconnect)
        if [[ $repo_add == *"gpg: keyserver receive failed: General error"* ]];
        then
            apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7937C393082992E5D6E4A60453FC26B43838D761
        fi
        apt-get update
        apt-get install globalprotect-openconnect
        gpclient-info
        exit
    else
        printf "\nERROR: Linux Distribution not found.\n\n"
        exit
fi
