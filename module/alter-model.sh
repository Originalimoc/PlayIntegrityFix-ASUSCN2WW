#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=$1
LOGFILE=$2

MODELLIST="`getprop | grep ASUS_AI2201_A | awk -F '[' '{print $2}' | awk -F ']' '{print $1}'`"
for MODELPROP in $MODELLIST
do
  OG="`getprop $MODELPROP`"
  TG="`echo "$OG" | sed 's/ASUS_AI2201_A/ASUS_AI2201_F/g'`"
  echo "$MODELPROP changed from \"$OG\" to \"$TG\"" >>$LOGFILE
  resetprop $MODELPROP "$TG" 2>&1 >>$LOGFILE
  echo "$MODELPROP=$TG" >> $MODDIR/system.prop
done
