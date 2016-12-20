function PrintHelp() {
  echo "MVS SDK Tools 0.0.1"
  echo "FTP Get/Put tool"
  echo ""
  echo "Usage:"
  echo ""
  echo " mvsstdds <options>"
  echo ""
  echo "  Options:"
  echo "    -g          - Get members from dataset to local files"
  echo "    -p          - Put local files to dataset members"
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
    (*)
      echo "MVSFTP001E: Invalid parameter $_opt. See -h or --help."
      exit -1
    ;;
  esac
  shift
done
if [[ !( -n "$_password" ) ]]; then
  read -s -p "Enter password for $_user@$_host: " _password
  echo ""
  if [[ !( -n "$_password" ) ]]; then
    echo "MVSSDK002E: MVS user password expected. See -h or --help."
    exit -1
  fi
fi
case $_action in
  ("GET")
    FTPDSGetFolder "$_host" "$_user" "$_password" "$_dsn" "$_path" "$_mask"
  ;;
  ("PUT")
    FTPDSPutFolder "$_host" "$_user" "$_password" "$_path" "$_mask" "$_dsn"
  ;;
esac
exit 0
