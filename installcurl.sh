#!/bin/bash
# update at cloudatcost
export DEBIAN_FRONTEND=noninteractive
apt-get -yqq update
apt-get -yqq install apt-transport-https
apt-get -yqq upgrade
apt-get -yqq dist-upgrade
apt-get -yqq install \
curl wget unzip vim rsync git byobu \
fail2ban bzip2 sudo build-essential icinga2
