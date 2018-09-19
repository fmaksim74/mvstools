#!/bin/bash
_mvs_host="rs22.rocketsoftware.com"
_mvs_userid="TS5671"
_mvs_userpw=""


function LoadFiles() {
  mkdir -p /home/max/workspace/mvsinc
  mkdir -p /home/max/workspace/mvsinc/IBM
  mkdir -p /home/max/workspace/mvsinc/Mrm
  mkdir -p /home/max/workspace/mvsinc/X11
  mkdir -p /home/max/workspace/mvsinc/Xm
  mkdir -p /home/max/workspace/mvsinc/arpa
  mkdir -p /home/max/workspace/mvsinc/arpa/IBM
  mkdir -p /home/max/workspace/mvsinc/libmilter
  mkdir -p /home/max/workspace/mvsinc/java_classes
  mkdir -p /home/max/workspace/mvsinc/metal
  mkdir -p /home/max/workspace/mvsinc/metal/IBM
  mkdir -p /home/max/workspace/mvsinc/net
  mkdir -p /home/max/workspace/mvsinc/net/IBM
  mkdir -p /home/max/workspace/mvsinc/netinet
  mkdir -p /home/max/workspace/mvsinc/netinet/IBM
  mkdir -p /home/max/workspace/mvsinc/skrb
  mkdir -p /home/max/workspace/mvsinc/sys
  mkdir -p /home/max/workspace/mvsinc/sys/IBM
  mkdir -p /home/max/workspace/mvsinc/rpc
  mkdir -p /home/max/workspace/mvsinc/uil

ftp -n -i "$_mvs_host" << End-Of-Session
user "${_mvs_userid,,}" "$_mvs_userpw"
cd /usr/include
lcd /home/max/workspace/mvsinc
mget *
End-Of-Session

  return 0
}

LoadFiles

exit 0
