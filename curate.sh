#!/bin/bash
verb=$1
case $verb in
 "local")
  if [ "$2" ]; then
   cid=$(ipfs add --offline --quiet "$2")
   echo added "$2" as $cid
  else
   echo Filename is a required argument >&2
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
  
