#!/bin/bash
#
# updateODMapps_WAS.sh  <Dmgr_home_location> <wasUserName> <wasPassword> 
#
# Update ODM enterprise apps 
#
# This example uses updateODMres.py jython code to update jrules-res-management.ear 
#  and jrules-res-htds.eara by using AdminApp.update() cmds taken from WAS Command Assistant
# Replace updateODMres.py with any set of wsadmin cmds taken from WAS Command Assistant as needed
# such as updating XU Resource Adaptor Config/properties
# --------------------------------

DMGR_HOME=$1
CURDIR=$PWD
user=$2
password=$3

if [[ $# != 3 ]] ; then
    echo "usage: updateODMapps_WAS.sh <Dmgr_home_location> <wasUserName> <wasPassword>"
    exit -1
fi

if [[ !  -f "$1/bin/startManager.sh" ]] ; then
   echo "$1 is not <Dmgr_home_location>" 
   echo "usage: updateODMapps_WAS.sh <Dmgr_home_location> <wasUserName> <wasPassword>"
   exit -1
fi

# uncomment for WAS 8.5.5, not required for WAS 9
# $DMGR_HOME/../../bin/managesdk.sh -setCommandDefault    -sdkname 1.8_64_bundled
# $DMGR_HOME/../../bin/managesdk.sh -setNewProfileDefault -sdkname 1.8_64_bundled 

$DMGR_HOME/bin/wsadmin.sh -lang jython -user $2 -password $3 -f updateODMres.py  

