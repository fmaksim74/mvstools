#!/bin/bash
#!/bin/bash
# Create local folders for project
# $1 - project root
function CreateLocalSpace() {
  if [[ ! -d $1 ]]; then
    return -1
  fi
  echo "Creating Load Module project folders in $1 ... "
  mkdir -p "$1/bldjcl/proc"
  mkdir -p "$1/lopt"
  mkdir -p "$1/lmod"
  mkdir -p "$1/llst"
  mkdir -p "$1/ltrm"
  return 0
}
# Allocate project datasets on host
# $1 - host
# $2 - user
# $3 - password
# $4 - dsn prefix
function CreateRemoteSpaceInDS() {
  if [[ ( ! $1 ) || ( ! $2 ) || ( ! $3 ) || ( ! $4 ) ]]; then
    return -1
  fi
  sshpass -p "$3" ssh "${2,,}@$1" << End-Of-Session
tsocmd "ALLOCATE DATASET('${4^^}.BLDJCL')   NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.BLDJCLP')  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.LOPT')     NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.LMOD')     NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.LEXP')     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.LPRN')     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(121)  RECFM(F,B,A) DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.LTRM')     NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.LOADLIB')  NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(U,V)   DSORG(PO) DSNTYPE(LIBRARY,2)"
exit
End-Of-Session
  return 0
}
# Generate default JCL files
# $1 - project root
function GenDefaultJcl() {
#  if [[ ! ( -d $1 ) ]]; then
#    return -1
#  fi
#  local _jcl_file="$1/asmjcl/proc/asma90.jcl"
#cat > "$_jcl_file" << EOF
#//ASSEMBLY PROC HLQ='',MEM='',OPT='DEFOPT'
#//*
#//DOASSMBL     EXEC PGM=ASMA90,PARM=OBJECT
#//SYSIN        DD DISP=SHR,DSN=&HLQ..ASM(&MEM.)
#//SYSLIN       DD DISP=SHR,DSN=&HLQ..ASMOBJ(&MEM.)
#//SYSLIB       DD DISP=SHR,DSN=SYS1.MACLIB
#//             DD DISP=SHR,DSN=&HLQ..ASMMAC
#//ASMAOPT      DD DISP=SHR,DSN=&HLQ..ASMOPT(&OPT.)
#//SYSPRINT     DD DISP=SHR,DSN=&HLQ..ASMLST(&MEM.)
#//SYSADATA     DD DISP=SHR,DSN=&HLQ..ASMADATA(&MEM.)
#//SYSUT1       DD DISP=SHR,DSN=&HLQ..ASMWF(&MEM.)
#//ASSEMBLY PEND
#EOF
return 0
}
# Generate jcl procedure for assembler source file compiling
# $1 - project root
# $2 - c file name
# $3 - dsn prefix
function GenFileCompileJcl() {
#  fname="${2##*/}"
#  fname="${fname%%.*}"
#  fext="${fn##*.}"
# Gen proc
#//LIBSRCH JCLLIB ORDER=${3^^}.ASMJCLP
#//*
#  local  _jcl_file="$1/asmjcl/proc/${fname,,}.jcl"
#cat > "$_jcl_file" << EOF
#//${fname^^} PROC
#//*Compile ${fname^^}
#//*
#EOF
#  if [[ -f "$1/asmopt/$fname.opt" ]]; then
#cat >> "$_jcl_file" << EOF
#//COMPILE EXEC ASMA90,HLQ=${3^^},MEM=${fname^^},OPT=${fname^^}
#EOF
#  else
#cat >> "$_jcl_file" << EOF
#//COMPILE EXEC ASMA90,HLQ=${3^^},MEM=${fname^^},OPT=DEFOPT
#EOF
#  fi
#cat >> "$_jcl_file" << EOF
#//${fname^^} PEND
#EOF

# Make job
#  local _jcl_file="$1/asmjcl/${fname,,}.jcl"
#cat > "$_jcl_file" << EOF
#//${fname^^} JOB 'Compile ${fname^^}',
#//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
#//*
#//LIBSRCH JCLLIB ORDER=${3^^}.ASMJCLP
#//*
#//COMPILE EXEC ${fname^^}
#EOF
  return 0
}
# Generate compile JCL files
# $1 - project root
# $2 - dsn prefix
function GenProjectCompileJcl() {
#  if [[ ( ! -d $1 ) || ( ! $2 ) ]]; then
#    return -1
#  fi
#  local _jcl_file="$1/asmjcl/asmall.jcl"
#cat > "$_jcl_file" << EOF
#//ASMALL JOB 'Compile assembler sources',
#//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
#//*
#//LIBSRCH JCLLIB ORDER=$2.ASMJCLP
#//*
#EOF
#  for fn in $(find "$1/asm" -maxdepth 1 -type f -name "*.asm"); do
#    GenFileCompileJcl "$1" "$fn" "$2"
#    fname="${fn##*/}"
#    fname="${fname%%.*}"
#    fext="${fn##*.}"
#cat >> "$_jcl_file" << EOF
#//COMPILE EXEC ${fname^^}
#EOF
#  done
  return 0
}

function PrintHelp() {
  echo "MVS SDK Tools 0.0.1"
  echo "Load Module project tool"
  echo ""
  echo "Usage:"
  echo ""
  echo " mvslmod <command> <options>"
  echo ""
  echo "  Commands:"
  echo "    -n          - Create new Load Module project in root specified by -r option"
  echo "    -g          - Get project files from datasets"
  echo "    -p          - Put project files to datasets"
  echo "    -j          - Generate/Update link JCLs"
  echo "    -o          - Get linker outputs"
  echo "  Options:"
  echo "    -h:host     - Host name"
  echo "    -u:user     - User name"
  echo "    -s:password - User password. It will be prompt if omited."
  echo "    -r:path     - HLASM project root"
  echo "    -q:dsn      - Datasets name prefix"
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
    ("-n")
      _action="NEW"
    ;;
    ("-g")
      _action="GET"
    ;;
    ("-p")
      _action="PUT"
    ;;
    ("-j")
      _action="JCL"
    ;;
    ("-o")
      _action="OUT"
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
    ("-r")
      _path="${_opt:3}"
    ;;
    ("-q")
      _dsn="${_opt:3}"
    ;;
    (*)
      echo "MVSLM0001E: Invalid parameter $_opt. See -h or --help."
      exit -1
    ;;
  esac
  shift
done
if [[ ("$_action" == "NEW" || "$_action" == "GET" || "$_action" == "PUT" || "$_action" == "OUT" )  && ( -z "$_host" ) ]]; then
  echo "MVSLM0002E: Host name expected for action $_action. See -h or --help."
  exit -1
fi
if [[ ("$_action" == "NEW" || "$_action" == "GET" || "$_action" == "PUT" || "$_action" == "OUT" ) && ( -z "$_user" ) ]]; then
  echo "MVSLM0003E: User name expected for action $_action. See -h or --help."
  exit -1
fi
if [ -z $_path ]; then
  echo "MVSLM0004E: Project root expected. See -h or --help."
  exit -1
fi
if [ -z $_dsn ]; then
  echo "MVSLM0005E: Project dataset prefix expected. See -h or --help."
  exit -1
fi
if [[ ("$_action" == "NEW" || "$_action" == "GET" || "$_action" == "PUT" || "$_action" == "OUT" ) && ( -z "$_password" ) ]]; then
  read -s -p "Enter password for $_user@$_host: " _password
  echo ""
  if [ -z "$_password" ]; then
    echo "MVSLM0006E: MVS user password expected. See -h or --help."
    exit -1
  fi
fi
case $_action in
  ("NEW")
    CreateLocalSpace "$_path"
#    GenDefaultJcl "$_path"
    CreateRemoteSpaceInDS "$_host" "$_user" "$_password" "$_dsn"
  ;;
  ("GET")
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.BLDJCL -d:$_path/bldjcl -m:*.jcl
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.BLDJCLP -d:$_path/bldjcl/proc -m:*.jcl
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.LOPT -d:$_path/lopt -m:*.opt
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.LMOD -d:$_path/lopt -m:*.mod
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.LPRN -d:$_path/llst -m:*.lst
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.LTRM -d:$_path/ltrm -m:*.trm
  ;;
  ("PUT")
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/bldjcl -m:*.jcl -f:${_dsn^^}.BLDJCL
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/bldjcl/proc -m:*.jcl -f:${_dsn^^}.BLDJCLP
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/lopt -m:*.opt -f:${_dsn^^}.LOPT
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/lmod -m:*.mod -f:${_dsn^^}.LMOD
  ;;
  ("JCL")
#    GenProjectCompileJcl "$_path" "$_dsn"
  ;;
  ("OUT")
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.LPRN -d:$_path/llst -m:*.lst
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.LTRM -d:$_path/ltrm -m:*.trm
  ;;
esac
exit 0
