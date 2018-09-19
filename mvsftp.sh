#!/bin/bash
#*****************************************************************************************************************************#
#  mvsftp.sh                                                                                                                  #
#                                                                                                                             #
#  Author: MIF                                                                                                                #
#  Last Edited: 2016/10/24                                                                                                    #
#                                                                                                                             #
#  Upload and Download files to/from partitioned datasets on mainframe through FTP.                                           #
#                                                                                                                             #
#  Support to modes:                                                                                                          #
#     1) ASCII with file encoding by ftp session between IBM-1047 and UTF-8. Use it for VB datasets.                          #
#        CAUTION! Don`t use it if file/members contains specific chars as ^,[,] and members encoding is not IBM-1047.         #
#     2) BINARY with custom encoding between IBM-037 and UTF-8. Use it for FB datasets.                                       #
#                                                                                                                             # 
#  See -h for detailes.                                                                                                       # 
#*****************************************************************************************************************************# 
# String routine. Extend string in $1 to length in $2
# $1 - string to extend
# $2 - length to extend
function ExtendString() {
  local _str="$1"
  if [[ !$2 ]]; then
    local _len=80
  fi
  while [[ ${#_str} -lt $_len ]] ; do
    _str="$_str "
  done
  
  echo "$_str"
}
# FTP routine. Upload files to PDS members
# $1 - host
# $2 - userid
# $3 - password
# $4 - full path
# $5 - file mask
# $6 - full dsn of PDS
# $7 - reclen
function FTPDSPutFolder() {
  if [[  ( ! $1 ) || ( ! $2 )  || ( ! $3 ) || !( -d "$4" ) || ( ! $5 )  || ( ! $6 ) ]]; then
    return -1
  fi
  if [[ -z "$7" ]]; then
    local _mode="ascii"
  else
    local _mode="binary"
  fi
  local _ws_tmp="/tmp/mvs/$4"
  rm -r -f  "$_ws_tmp"
  mkdir -p "$_ws_tmp"
  if [[ !( -d "$_ws_tmp" ) ]]; then
    return -1
  fi
  for fname in $( find "$4" -maxdepth 1 -type f -name "$5" )
  do
    local fn=${fname##*/}  # get file name with extension
    local fn=${fn%%.*}     # get file name without extension
    if [[ -z "$7" ]]; then
      cp "$fname" "$_ws_tmp/${fn^^}"
    else
      local _lnum=1
      cat "$fname" | while IFS= read _line; do
        while [[ ${#_line} -lt $7 ]]; do _line="$_line "; done
        while [[ ${#_line} -gt $7 ]]; do
          _line=$( echo "$_line" | rev | sed 's/  / /' | rev )
        done
        echo -n "$_line" | iconv -f UTF-8 -t CP037 >> "$_ws_tmp/${fn^^}" 
        ((_lnum++));	
      done
    fi 
    if [ ! $? -eq 0 ] ; then
      echo "MVSFTP003E: Error copy file from $fname to $_ws_tmp/${fn^^}"
    fi
  done
  ftp -n -i "$1" << End-Of-Session
user "${2,,}" "$3"
$_mode
lcd "$_ws_tmp"
cd "'$6'"
mput *
by
End-Of-Session
  return 0
}
# FTP routine. Download PDS members to files
# $1 - host
# $2 - userid
# $3 - password
# $4 - full dsn of PDS
# $5 - full path
# $6 - file mask
# $7 - reclen
function FTPDSGetFolder() {
  if [[ (! $1 ) || ( ! $2 ) || ( ! $3 )  || ( ! $4 )  || ( ! ( -d $5 ) )  || ( ! $6 ) ]] ; then
    return -1
  fi
  if [[ -z "$7" ]]; then
    local _mode="ascii"
  else
    local _mode="binary"
  fi
  local _ws_tmp="/tmp/mvs/$5"
  rm -r -f  "$_ws_tmp"
  mkdir -p "$_ws_tmp"
  if [[ !( -d "$_ws_tmp" ) ]] ; then
    return -1
  fi
  ftp -n -i "$1" << End-Of-Session
user "${2,,}" "$3"
$_mode
lcd "$_ws_tmp"
cd "'$4'"
mget *
by
End-Of-Session
  for fname in $( find "$_ws_tmp" -maxdepth 1 -type f); do
    local fn=${fname##*/}
    if [[ -z "$7" ]]; then
# Fix ^,[,] symbols in file after 1047 to UTF convert
      sed "s/\xB5/\x5E/" "$fname" | sed "s/\x8D/\x5B/" | sed "s/\xD9/\x5D/" > "$5/${fn,,}.${6##*.}"
    else
# Convert from 037 to UTF-8 and split to lines with specified reclen
      iconv -f CP037 -t UTF-8 "$fname" | sed -r "s/(.{$7})/\1\n/g" > "$5/${fn,,}.${6##*.}"
    fi
    if [ ! $? -eq 0 ] ; then
      echo "MVSFTP004E: Error while coping file from $fname to "$5/${fn,,}.${6##*.}""
    fi
  done
  return 0
}
function PrintHelp() {
  echo "MVS SDK Tools 0.0.1"
  echo "FTP Get/Put tool"
  echo ""
  echo "Usage:"
  echo ""
  echo " mvsftp <options>"
  echo ""
  echo "  Options:"
  echo "    -g          - Get members from dataset to local files"
  echo "    -p          - Put local files to dataset members"
  echo "    -b:<reclen> - Use binary transfer mode for fixed block dataset and convert it"
  echo "    -h:host     - Host name"
  echo "    -u:user     - User name"
  echo "    -s:password - User password. It will be prompt if omited."
  echo "    -d:path     - Local path"
  echo "    -m:mask     - File mask as *.ext. For example *.cpp"
  echo "    -f:dsn      - Full qualified dataset name (FQDSN)"
  echo ""
}

##################################################################################################################
# Main routine
##################################################################################################################
if [[ ( $# == 0 || ( $# == 1 && ("$1" = "-h" || "${1}" = "--help" || "${1}" = "-?" || "${1}" = "?") ) ) ]]; then
  PrintHelp
  exit 0
fi
#-----------------------------------------------------------------------------------------------------------------
# Parse command line parameters
while [[ -n "$1" ]]; do
  _opt="$1"
  case "${_opt:0:2}" in
    ("-g")
      _action="GET"
    ;;
    ("-p")
      _action="PUT"
    ;;
    ("-h")
      _host="${_opt:3}"
    ;;
    ("-u")
      _user="${_opt:3}"
    ;;
    ("-s")
      _password="${_opt:3}"
    ;;
    ("-d")
      _path="${_opt:3}"
    ;;
    ("-m")
      _mask="${_opt:3}"
    ;;
    ("-f")
      _dsn="${_opt:3}"
    ;;
    ("-b")
      _rlen="${_opt:3}"
    ;;
    (*)
      echo "MVSFTP001E: Invalid parameter $_opt. See -h or --help."
      exit -1
    ;;
  esac
  shift
done
if [ -z $_host ]; then
  echo "MVSFTP002E: Host name expected for action $_action. See -h or --help."
  exit -1
fi
if [ -z $_user ]; then
  echo "MVSFTP003E: User name expected for action $_action. See -h or --help."
  exit -1
fi
if [ -z $_path ]; then
  echo "MVSFTP004E: Project root expected. See -h or --help."
  exit -1
fi
if [ -z $_dsn ]; then
  echo "MVSFTP005E: Project dataset prefix expected. See -h or --help."
  exit -1
fi
if [ -z "$_password" ]; then
  read -s -p "Enter password for $_user@$_host: " _password
  echo ""
  if [ -z "$_password" ]; then
    echo "MVSFTP006E: MVS user password expected. See -h or --help."
    exit -1
  fi
fi
case $_action in
  ("GET")
    FTPDSGetFolder "$_host" "$_user" "$_password" "$_dsn" "$_path" "$_mask" "$_rlen"
  ;;
  ("PUT")
    FTPDSPutFolder "$_host" "$_user" "$_password" "$_path" "$_mask" "$_dsn" "$_rlen"
  ;;
esac
exit 0
