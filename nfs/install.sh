#!/bin/sh
FSDir=/tmp
NFSClient=10.169.216.89
ClientUid=501


yum install -y showmount || return $?
echo "$FSDir $NFSClient/32(rw,no_root_squash,no_all_squash,sync,no_subtree_check,anonuid=$ClientUid,anongid=$ClientUid)" >> /etc/exports || return $?
echo >> /etc/sysconfig/nfc << EOF
RQUOTAD_PORT=875
LOCKD_TCPPORT=32803
LOCKD_UDPPORT=32769
MOUNTD_PORT=892
STATD_PORT=662
STATD_OUTGOING_PORT=2020
EOF
if [ $? -ne 0 ]; then return 1; fi
chkconfig rpcbind on || return $?
chkconfig nfs on || return $?
service rpcbind start || return $?
service nfc start || return $?
exportfs -r
