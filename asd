#!/bin/bash

#
# choose a device to run adb on
#

function devices() {
   for i in `adb devices | grep device | grep -v List| cut -f1`;
   do
      echo -n "$i: "
      adb -s $i shell getprop \
         | grep "ro.product.manufacturer\|ro.product.brand\|ro.product.model\|ro.build.version.release\|ro.build.version.sdk" \
         | cut -d: -f2 | tr -d \\\n\\\r | tr [] " " ; echo
   done
}

case "$1" in
"-h"|"--help")
   echo "Usage: $0 [number] commands";
   echo "       noargs: list devices"
   echo "       [number] commands: choose device, run commands with adb set it"
   echo "       commands: prompts for device, run commands with adb set to it"
   echo ""
   echo "       e.g, `basename $0` 1 adb shell input text 5551212"
;;
"")
   devices
   echo "(-h or --help for help)";
;;
[0-9])
   d=$1
   ser=`adb devices |grep device | grep -v List| cut -f1 | head -$d | tail -1`
   shift

   if [[ $ser == "" ]]; then
       echo "No device!"
       exit 1
   fi

   desc=`adb -s $ser shell getprop ro.product.model`
   echo -n "]0;"$desc""

   case $1 in
   "") test ;;
   *) (export ANDROID_SERIAL=$ser; "$@") ;;
   esac
;;
"a"|"all")
   sers=`adb devices |grep device | grep -v List| cut -f1`
   shift

   if [[ $sers == "" ]]; then
       echo "No device!"
       exit 1
   fi

   for ser in $sers
   do
     desc=`adb -s $ser shell getprop ro.product.model`
     echo -n "]0;"$desc""
     case $1 in
     "") test ;;
     *) (export ANDROID_SERIAL=$ser; "$@") ;;
     esac

   done
;;
*)
   count=`adb devices | awk -F '\t' 'NR>1 {if($1 != null) print NR}' | wc -l | xargs`
   if [ $count -gt 1 ]; then
     echo 'Devices:'
     devices | awk -F '\t' '{if($1 != null) print NR ") " $0}'
     printf 'a|all) All'
     printf '\nSelect device (1): '
     read dev_nr
     if [ "" == "$dev_nr" ]; then
       dev_nr=1
     elif [ "$dev_nr" = "a" -o "$dev_nr" = "all" ]; then
       for (( i=1; i<=$count; i++ ))
       do
         line_nr=$((i+1))
         ser=`adb devices | awk -F '\t' "NR==${line_nr} {print \\$1}"`
         (export ANDROID_SERIAL=$ser; "$@")
       done
       exit 0

     elif [ $dev_nr -gt $count ] || [ $dev_nr -lt 1 ]; then
       echo "Wrong device number!"
       exit 1
     fi
   else
     dev_nr=1
   fi
   line_nr=$((dev_nr+1))
   ser=`adb devices | awk -F '\t' "NR==${line_nr} {print \\$1}"`
   (export ANDROID_SERIAL=$ser; "$@")
;;
esac

