#!/bin/bash
_src_name=$1
_dst_name=$2
_file_ext=$3

_mvs_host="rs22.rocketsoftware.com"
_mvs_userid="TS5671"
_mvs_userpw=""

function LoadFiles() {
  mkdir -p "$_dst_name"

ftp -n -i "$_mvs_host" << End-Of-Session
user "${_mvs_userid,,}" "$_mvs_userpw"
cd "'$_src_name'"
lcd "$_dst_name"
mget *
by
End-Of-Session

  return 0
}

function RenameFiles() {
  cd "$_dst_name"
  for fname in $( find . -maxdepth 1 -type f ! -name "*.*" )
  do
    mv "$fname" "${fname,,}.$_file_ext"
  done
  return $?
}

function main() {
  if [[ ( ! "$_src_name" )]]; then
    echo "ERROR: No source name"
    exit 1
  fi

  if [[ ( ! "$_dst_name" )]]; then
    echo "ERROR: No destination name"
    exit 1
  fi

  if [[ ( ! "$_file_ext" )]]; then
    echo "ERROR: No file type (extension)"
    exit 1
  fi

  LoadFiles
  RenameFiles

  exit 0
}

main
