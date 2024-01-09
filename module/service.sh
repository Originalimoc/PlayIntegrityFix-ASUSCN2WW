# Conditional sensitive properties

resetprop_if_diff() {
    local NAME=$1
    local EXPECTED=$2
    local CURRENT=$(resetprop $NAME)

    [ -z "$CURRENT" ] || [ "$CURRENT" == "$EXPECTED" ] || resetprop $NAME $EXPECTED
}

resetprop_if_match() {
    local NAME=$1
    local CONTAINS=$2
    local VALUE=$3

    [[ "$(resetprop $NAME)" == *"$CONTAINS"* ]] && resetprop $NAME $VALUE
}

# Magisk recovery mode
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

# SELinux
if [ -n "$(resetprop ro.build.selinux)" ]; then
    resetprop --delete ro.build.selinux
fi

# use toybox to protect *stat* access time reading
if [ "$(toybox cat /sys/fs/selinux/enforce)" == "0" ]; then
    chmod 640 /sys/fs/selinux/enforce
    chmod 440 /sys/fs/selinux/policy
fi

modelprops="ro.product.model
ro.product.bootimage.model
ro.product.odm.model
ro.product.product.model
ro.product.system.model
ro.product.system_ext.model
ro.product.vendor.model
ro.product.vendor_dlkm.model"
for propname in $modelprops
do
    resetprop $propname "ASUS_AI2201_F"
    resetprop -n $propname "ASUS_AI2201_F"
    resetprop -p $propname "ASUS_AI2201_F"
    resetprop -n $propname "ASUS_AI2201_F"
    resetprop $propname "ASUS_AI2201_F"
done


MODDIR=${0%/*}
LOGFILE=$MODDIR/s.log
rm -rf $LOGFILE

CNPROPLISTR="`getprop | grep CN | grep -Fe "[CN]" -e "CN_AI2201" -e "release-keys"`"
CNPROPLISTFiltered="`echo "$CNPROPLISTR" | grep -ve vendor.asus.operator.iso-country -e persist.vendor.asus.ship_location -e persist.vendor.fota | awk -F '[' '{print $2}' | awk -F ']' '{print $1}'`"

for CP in $CNPROPLISTFiltered
do
  OG="`getprop $CP`"
  TG="`echo "$OG" | sed 's/CN/WW/g'`"
  echo "$CP changed from \"$OG\" to \"$TG\"" >>$LOGFILE
  resetprop $CP "$TG" 2>&1 >>$LOGFILE
  echo "$CP=$TG" >> $MODDIR/system.prop
done

sh $MODDIR/alter-model.sh $MODDIR $LOGFILE

resetprop ro.boot.image.valid "Y"
resetprop vendor.asus.image.valid "Y"
setprop ro.boot.image.valid "Y"
setprop vendor.asus.image.valid "Y"


# late props which must be set after boot_completed for various OEMs
until [ "$(resetprop sys.boot_completed)" == "1" ]; do
	sleep 1
done

# Avoid breaking Realme fingerprint scanners
resetprop_if_diff ro.boot.flash.locked 1
# Avoid breaking Oppo fingerprint scanners
resetprop_if_diff ro.boot.vbmeta.device_state locked
# Avoid breaking OnePlus display modes/fingerprint scanners
resetprop_if_diff vendor.boot.verifiedbootstate green
# Avoid breaking OnePlus/Oppo display fingerprint scanners on OOS/ColorOS 12+
resetprop_if_diff ro.boot.verifiedbootstate green
resetprop_if_diff ro.boot.veritymode enforcing
resetprop_if_diff vendor.boot.vbmeta.device_state locked

# Restrict permissions to socket file
chmod 440 /proc/net/unix
