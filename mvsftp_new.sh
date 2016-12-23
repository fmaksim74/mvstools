#!/bin/bash
#******************************************************************************************************************************#
#  mvsftp.sh                                                                                                                   #
#                                                                                                                              #
#  Author: MIF                                                                                                                 #
#  Last Edited: 2016/10/24                                                                                                     #
#                                                                                                                              #
#  Upload and Download files to/from partitioned datasets on mainframe through FTP.                                            #
#                                                                                                                              #
#  Support to modes:                                                                                                           #
#     1) ASCII with file encoding by ftp session between IBM-1047 and UTF-8. Use it for VB datasets.                           #
#        CAUTION! Don`t use it if file/members contains specific chars as ^,[,] and members encoding is not IBM-1047.          #
#     2) BINARY with custom encoding between IBM-037 and UTF-8. Use it for FB datasets.                                        #
#                                                                                                                              # 
#  See -h for detailes.                                                                                                        # 
#******************************************************************************************************************************# 
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
# $4 - dsn
# $5 - type
# $6 - rlen
# $7 - cp
# $8 - full path
# $9 - file mask
function FTPDSPutFolder() {
  local _ws_tmp="/tmp/mvs/$4"
  rm -r -f  "$_ws_tmp"
  mkdir -p "$_ws_tmp"
  if [[ !( -d "$_ws_tmp" ) ]]; then
    return -1
  fi
  for fname in $( find "$8" -maxdepth 1 -type f -name "$9" )
  do
    local fn=${fname##*/}  # get file name with extension
    local fn=${fn%%.*}     # get file name without extension
    cp "$fname" "$_ws_tmp/${fn^^}"
    if [ ! $? -eq 0 ] ; then
      echo "MVSFTP003E: Error copy file from $fname to $_ws_tmp/${fn^^}"
    fi
  done
  ftp -n -i "$1" << End-Of-Session
user "${2,,}" "$3"
ascii
site UCST
site SB=("$7",UTF-8)
site MB=("$7",UTF-8)
lcd "$_ws_tmp"
cd "'$4'"
mput *
by
End-Of-Session
  return 0
}
# FTP routine. Download PDS members to files
# $1 - host
# $2 - userid
# $3 - password
# $4 - dsn
# $5 - type
# $6 - rlen
# $7 - cp
# $8 - full path
# $9 - file mask
function FTPDSGetFolder() {
  local _ws_tmp="/tmp/mvs/$8"
  rm -r -f  "$_ws_tmp"
  mkdir -p "$_ws_tmp"
  if [[ !( -d "$_ws_tmp" ) ]] ; then
    return -1
  fi
  local _dt=$(date +%Y%m%d%H%M%S%N)
  local _sf="/tmp/mvs/$_dts"
  local _lf="/tmp/mvs/$_dtl"
  ftp -n -i "$1" << End-Of-Session
user "${2,,}" "$3"
ascii
site UCST
site SB=("$7",UTF-8)
site MB=("$7",UTF-8)
lcd "$_ws_tmp"
cd "'$4'"
mget *
by
End-Of-Session
  for fname in $( find "$_ws_tmp" -maxdepth 1 -type f); do
    local fn=${fname##*/}
    mv -f "$fname" "$8/${fn,,}.${9##*.}"
    if [ ! $? -eq 0 ] ; then
      echo "MVSFTP004E: Error while coping file from $fname to "$8/${fn,,}.${9##*.}""
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
  echo "   Actions"
  echo "    -g           - Get members from dataset to local files"
  echo "    -p           - Put local files to dataset members"
  echo "   Host info"
  echo "    -h:host      - Host name"
  echo "    -u:user      - User name"
  echo "    -s:password  - User password. It will be prompt if omited."
  echo "   Local place"
  echo "    -d:path      - Local path"
  echo "    -m:mask      - File mask. If not specified all files will be processe."
  echo "   Remote place"
  echo "    -f:dsn       - Full qualified dataset name (FQDSN). For PS a file name will be add to FQDSN."
  echo "    -t:<type>    - Dataset type S (single) or L (library)"
  echo "    -l:<reclen>  - Reclen for FB datasets or max reclen for VB datasets"
  echo "    -c:<charset> - Set transfer chatset 037 or 1047"
  echo ""
}

########
# Main #
########
if [[ ( $# == 0 || ( $# == 1 && ("$1" = "-h" || "${1}" = "--help" || "${1}" = "-?" || "${1}" = "?") ) ) ]]; then
  PrintHelp
  exit 0
fi
#-------------------------------------------------------------------------------------------------------------------------------
# Parse command line parameters
while [[ -n "$1" ]]; do
  _opt="$1"
  case "${_opt:0:2}" in
# Action
    ("-g")
      _action="GET"
    ;;
    ("-p")
      _action="PUT"
    ;;
# Host
    ("-h")
      _host="${_opt:3}"
    ;;
    ("-u")
      _user="${_opt:3}"
    ;;
    ("-s")
      _password="${_opt:3}"
    ;;
# Local
    ("-d")
      _path="${_opt:3}"
    ;;
    ("-m")
      _mask="${_opt:3}"
    ;;
# Remote
    ("-f")
      _dsn="${_opt:3}"
    ;;
    ("-t")
      _type="${_opt:3}"
      _type="${_type^^}"
    ;;
    ("-l")
      _rlen="${_opt:3}"
    ;;
    ("-c")
      _cp="${_opt:3}"
    ;;
    (*)
      echo "MVSFTP001E: Invalid parameter $_opt. See -h or --help."
      exit -1
    ;;
  esac
  shift
done
if [ -z "$_action" ]; then
  echo "Action expected. See -h or --help"
  exit -1
fi
if [ -z $_host ]; then
  echo "MVSFTP002E: Host name expected. See -h or --help."
  exit -1
fi
if [ -z $_user ]; then
  echo "MVSFTP003E: User name expected. See -h or --help."
  exit -1
fi
if [ -z $_path ]; then
  echo "MVSFTP004E: Local path expected. See -h or --help."
  exit -1
fi
if [ -z $_mask ]; then
  echo "MVSFTP004E: File mask expected. Cannot write files with mixed types. See -h or --help."
fi
if [ -z $_dsn ]; then
  echo "MVSFTP005E: Dataset name expected. See -h or --help."
  exit -1
fi
if [ -z $_type ]; then
  echo "MVSFTP005I: Dataset type not specified. Assume L (library)."
  _type="L"
fi

if [ "$_type" = "S" ]; then
echo "Type=$_type" 
  if [ -n $(echo "$_mask" | grep "[*?]") ]; then
    echo "MVSFTP004E: Wide file mask with non partitioned dataset. Cannot write more than one file to non partitioned dataset."
    exit -1
  fi
fi
if [ -z $_cp ]; then
  echo "MVSFTP005I: Dataset charset mot specified. Use 037 as default."
  _cp="037"
fi
if [ -z "$_password" ]; then
  read -s -p "Enter password for $_user@$_host: " _password
  echo ""
  if [ -z "$_password" ]; then
    echo "MVSFTP006E: Password expected. See -h or --help."
    exit -1
  fi
fi
case $_action in
  ("GET")
    FTPDSGetFolder "$_host" "$_user" "$_password" "$_dsn" "$_type" "$_rlen" "$_cp" "$_path" "$_mask"
  ;;
  ("PUT")
    FTPDSPutFolder "$_host" "$_user" "$_password" "$_dsn" "$_type" "$_rlen" "$_cp" "$_path" "$_mask"
  ;;
esac
exit 0

