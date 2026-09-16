#!/bin/bash
verb=$1
case $verb in
 "local")
  if [ "$2" ]; then
   cid=$(ipfs add --offline $2)
  else
   echo Filename is a required argument >&2
  fi;;
  
