#!/bin/bash
# 
# killPIDs.sh $1
#------------------------------
delay="20s"

if [ -z $1 ] ; then
 echo "usage: killPIDs.sh <arg1>"
 echo " kills all pids containing arg1 after a $delay delay."
 echo " example: $ killPIDs.sh java"
 echo "   kills all running java processes"
 exit
fi

pids=$( ps -ef | grep $1  | gawk '{ print $2 }'  )
if [[ $pids ]] ; then 
 echo "killing pids pids containing $1 in $delay, CNTL-C now to abort."
 echo ""
 sleep $delay 
 for pid in $pids ;  do
   if [[ $(ps --no-headers -p $pid) ]] ; then 
     kill -9 $pid
   fi 
 done
fi
