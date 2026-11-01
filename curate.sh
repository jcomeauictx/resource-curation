#!/bin/bash
CID='^(Qm[1-9A-HJ-NP-Za-km-z]{44}|b[a-z2-7]{58})$'
IPFS='echo ipfs' # precede with "echo" until basic testing complete
verb=$1
object=$2
labelnames="${@3}"
case $verb in
 "local")
  if [ "$object" ]; then
   if $(grep -e "$CID" "$object"); then
    if [ -e "$object" ]; then
     # matches CID format but also exists as a file: abort
     echo Cannot determine whether "'$object'" is filename or CID >&2
     exit 1
    elif [ -e "$object" ]; then  # it's a file
     cid=$(ipfs add --offline --quiet "$object")
     echo added "$2" as $cid >&2
    else
     echo "'$object'" is not a filespec nor an IPFS CID >&2
     exit 1
    fi
   else
    cid=$object
   fi
   for label in $labelnames; do
    nsupdate -k $DNSKEY <<-EOF
	server your.bind9.server
	zone yourdomain.com
	update delete _dnslink.yourdomain.com TXT
	update add _dnslink.yourdomain.com 60 TXT "/ipfs/$cid"
	send
	EOF
   done
  else
   echo 'Usage: $0 $verb FILENAME|CID [LABELNAME ...]' >&2
   exit 2
  fi;;
 "remove")
  if [ "$2" ]; then
   ipfs pin rm "$2"
   ipfs repo gc
  else
   echo CID is a required argument >&2
  fi;;
 "publish")
  if [ "$2" ]; then
   ipfs dht provide "$2"
  else
   echo CID is a required argument >&2
  fi;;
esac
