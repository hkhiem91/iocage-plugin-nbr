#!/bin/sh

PRODUCT='NAKIVO Backup & Replication'
URL="http://download2275.mediafire.com/rc46s1oqf11g/k8q2rntbkj0y1zl/NAKIVO_Backup_Replication_v10.7.0.65677_Installer-TRIAL.sh"
SHA256="ddcf3aed10e22abac48987637fab0a7c25e776ec757dfaba227a0121ce7a73a2"

PRODUCT_ROOT="/usr/local/nakivo"
INSTALL="inst.sh"

curl --fail --tlsv1.2 -o $INSTALL $URL
if [ $? -ne 0 -o ! -e $INSTALL ]; then
    echo "ERROR: Failed to get $PRODUCT installer"
    rm $INSTALL >/dev/null 2>&1
    exit 1
fi


sh ./$INSTALL -f -y -i "$PRODUCT_ROOT" --eula-accept --extract 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: $PRODUCT install failed"
    rm $INSTALL >/dev/null 2>&1
    exit 3
fi
rm $INSTALL >/dev/null 2>&1

#disable default HTTP ports redirect
SVC_PATH="$PRODUCT_ROOT/director"
awk 'BEGIN{A=0} /port="80/{A=1} {if (A==0) print $0} />/{A=0}' $SVC_PATH/tomcat/conf/server-linux.xml >$SVC_PATH/tomcat/conf/server-linux.xml_ 2>/dev/null
mv $SVC_PATH/tomcat/conf/server-linux.xml_ $SVC_PATH/tomcat/conf/server-linux.xml >/dev/null 2>&1

#enforce EULA
PROFILE=`ls "$SVC_PATH/userdata/"*.profile 2>/dev/null | head -1`
if [ "x$PROFILE" != "x" ]; then
    sed -e 's@"system.licensing.eula.must.agree": false@"system.licensing.eula.must.agree": true@' "$PROFILE" >"${PROFILE}_" 2>/dev/null
    mv "${PROFILE}_" "$PROFILE" >/dev/null 2>&1
fi

service nkv_dirsvc start >/dev/null 2>&1
