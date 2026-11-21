#!/bin/bash -x
CID='^(Qm[1-9A-HJ-NP-Za-km-z]{44}|b[a-z2-7]{58})$'
IPFS='echo ipfs' # precede with "echo" until basic testing complete
CONFIG=$HOME/.resource-curation/config.env
CONFDIR=$(dirname $CONFIG)
DNSKEY=/etc/bind/dnslink.key
verb=$1
object=$2
labelnames="${@:3}"
if [ -e "$CONFIG" ]; then
 source $CONFIG
else
 echo No configuration file located at $CONFIG >&2
 exit 1
fi
if [ ! -e $DNSKEY ]; then \
 echo 'Keyfile not properly installed, run `make install`' >&2
 exit 1
fi
# check only for PUBLIC_TLD, assume all other variables present if it is valid
if [ -z "$PUBLIC_TLD" ] || [ "$PUBLIC_TLD" = "unset" ]; then
 echo Must edit $CONFIG with valid values >&2
 exit 1
fi
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
   nsupdate -k $DNSKEY <<-EOF
	server $PRIVATE_NAMESERVER
	zone $PRIVATE_DOMAIN
	update delete _dnslink TXT
	update add _dnslink $PRIVATE_TTL TXT "/ipfs/$cid"
	send
	EOF
   for label in $labelnames; do
    echo adding $label as TXT record to $PRIVATE_DOMAIN >&2
    nsupdate -k $DNSKEY <<-EOF
	server $PRIVATE_NAMESERVER
	zone $PRIVATE_DOMAIN
	update add $(basename $label) $PRIVATE_TTL TXT "$label"
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
 "")
  echo Must specify one of: local remove publish >&2
  ;;
 *)
  echo verb "'$verb'" not recognized >&2
  false
  ;;
esac
