# Remove Play Services from Magisk Denylist when set to enforcing
if magisk --denylist status; then
    magisk --denylist rm com.google.android.gms
fi

# Conditional early sensitive properties

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

# RootBeer, Microsoft
resetprop_if_diff ro.build.tags release-keys

# Samsung
resetprop_if_diff ro.boot.warranty_bit 0
resetprop_if_diff ro.vendor.boot.warranty_bit 0
resetprop_if_diff ro.vendor.warranty_bit 0
resetprop_if_diff ro.warranty_bit 0

# OnePlus
resetprop_if_diff ro.is_ever_orange 0

# Other
resetprop_if_diff ro.build.type user
resetprop_if_diff ro.debuggable 0
resetprop_if_diff ro.secure 1

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
LOGFILE=$MODDIR/pfd.log

rm -rf $LOGFILE
cat $MODDIR/system.prop.persist > $MODDIR/system.prop

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

echo "`date`: done" >> $LOGFILE
