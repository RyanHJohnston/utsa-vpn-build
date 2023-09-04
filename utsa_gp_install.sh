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
            printf "\nRemoving installed version of GlobalProtect...\n\n"
            apt-get purge *globalprotect* -y
        fi

        case $linux_ver in
            14)
                ;&
            16)
                ;&
            18)
                FILE=$(apt-get install ./GlobalProtect_deb-*.deb)
				if [ -f "$FILE" ]; then
					printf "\nInstalling the .deb package...\n\n"
					apt-get install ./GlobalProtect_deb-*.deb
				else
					printf "\nInstalling the openconnect package...\n\n"
					add-apt-repository ppa:yuezk/globalprotect-openconnect -y
					apt-get update -y
					apt-get install globalprotect-openconnect -y
					verify-cert
					gpclient_info "sudo apt-get remove" "-openconnect"
				fi
				exit 0
                ;;
            *)
                FILE=$(apt-get install ./GlobalProtect_focal_deb-*.deb)
				if [ -f "$FILE" ]; then
					printf "\nInstalling the .deb package...\n\n"
					apt-get install ./GlobalProtect_focal_deb-*.deb
				else
					printf "\nInstalling the openconnect package...\n\n"
					add-apt-repository ppa:yuezk/globalprotect-openconnect -y
					apt-get update -y
					apt-get install globalprotect-openconnect -y
					verify-cert
					gpclient_info "sudo apt-get remove" "-openconnect"
				fi
                exit 0
                ;;
        esac
        ;;
    fedora)
        printf "$open_msg"

        yum_output=$(yum list installed | grep globalprotect)

        if [[ $yum_output == *"globalprotect.x86"* ]];
        then
            printf "\nInstallig most recent version of GlobalProtect\n\n"
            dnf install GlobalProtect_rpm-*.rpm
            gpclient_info "sudo dnf remove"
        else
            printf "\nInstalling globalprotect-openconnect\n\n"
            dnf install 'dnf-command(copr)' -y
            dnf copr enable yuezk/globalprotect-openconnect -y
            dnf install globalprotect-openconnect -y
            verify-cert
            gpclient_info "sudo dnf remove" "-openconnect"
        fi

        exit 0
        ;;
    rhel)
        ;&
    arch)
        printf "$open_msg"
        printf "\nInstalling most recent version of globalprotect-openconnect from the official Arch repository...\n\n"
        
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
    add-apt-repository ppa:yuezk/globalprotect-openconnect -y
    apt-get update -y
    apt-get install globalprotect-openconnect -y
    verify-cert	
    gpclient_info "sudo apt-get remove" "-openconnect"
    exit 0
else
    printf "\nERROR: Linux Distribution not found.\n\n"
fi

# If no distro was found, build from source
printf "\n\n\nNo distro was found, would you like to build from source? [Y/n]: "; read CHOICE;
if [ "$CHOICE" == [Yy] ]; then
    git clone https://github.com/yuezk/GlobalProtect-openconnect.git
    CWD=$(readlink -f .)
    cd GlobalProtect-openconnect
    ./scripts/build.sh
    verify-cert
    cd $CWD
    printf "The GlobalProtect-openconnect package was build from source, see their documentation on how to uninstall here: "
    printf "https://github.com/yuezk/GlobalProtect-openconnect\n"
    printf "To run the VPN, type: gpclient\n"
    printf "Portal address: vpn.utsa.edu\n"
    printf "If any errors were encountered while building from source, make sure the proper right packages are installed\n"
    printf "Contact ryanhjohnstoncollege@gmail.com for more support\n"
fi

printf "ERROR: No distro was found and not building from source, exiting now\n"
printf "Contact ryanhjohnstoncollege@gmail.com for more support\n"
exit 1

