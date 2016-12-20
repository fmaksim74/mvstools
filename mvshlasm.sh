#!/bin/bash
# Create local folders for project
# $1 - project root
function CreateLocalSpace() {
  if [[ ! $1 ]]; then
    return -1
  fi
  echo "Creating Assembler project folders in $1 ... "
  mkdir -p "$1/asm/mac"
  mkdir -p "$1/asmjcl/proc"
  mkdir -p "$1/asmopt"
  mkdir -p "$1/asmlst"
  mkdir -p "$1/asmadata"
  mkdir -p "$1/asmwf"
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
  sshpass -p "$3" ssh "${2,,}@${1,,}" << End-Of-Session
tsocmd "ALLOCATE DATASET('${4^^}.ASM')      NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.ASMMAC')   NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.ASMJCL')   NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.ASMJCLP')  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.ASMOPT')   NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.ASMLST')   NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(882)   DIR(1) LRECL(137)   RECFM(V,B,A) DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.ASMOBJ')   NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32720) DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET('${4^^}.ASMADATA') NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(32756) RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
#tsocmd "ALLOCATE DATASET('${4^^}.ASMWF')    NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(32756) RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
exit
End-Of-Session
  return 0
}
# Generate default JCL files
# $1 - project root
function GenDefaultJcl() {
  if [[ ! ( -d $1 ) ]]; then
    return -1
  fi
  local _jcl_file="$1/asmjcl/proc/asma90.jcl"
cat > "$_jcl_file" << EOF
//ASSEMBLY PROC HLQ='',MEM='',OPT='DEFOPT'
//*
//DOASSMBL     EXEC PGM=ASMA90,PARM=OBJECT
//SYSIN        DD DISP=SHR,DSN=&HLQ..ASM(&MEM.)
//SYSLIN       DD DISP=SHR,DSN=&HLQ..ASMOBJ(&MEM.)
//SYSLIB       DD DISP=SHR,DSN=SYS1.MACLIB
//             DD DISP=SHR,DSN=&HLQ..ASMMAC
//ASMAOPT      DD DISP=SHR,DSN=&HLQ..ASMOPT(&OPT.)
//SYSPRINT     DD DISP=SHR,DSN=&HLQ..ASMLST(&MEM.)
//SYSADATA     DD DISP=SHR,DSN=&HLQ..ASMADATA(&MEM.)
//*SYSUT1       DD DISP=SHR,DSN=&HLQ..ASMWF(&MEM.)
//ASSEMBLY PEND
EOF
return 0
}
# Generate jcl procedure for assembler source file compiling
# $1 - project root
# $2 - c file name
# $3 - dsn prefix
function GenFileCompileJcl() {
  fname="${2##*/}"
  fname="${fname%%.*}"
  fext="${fn##*.}"
# Make proc
  local  _jcl_file="$1/asmjcl/proc/${fname,,}.jcl"
  cat > "$_jcl_file" << EOF
//${fname^^} PROC HLQ=''
//*
//*Compile ${fname^^}
//*
EOF
  if [[ -f "$1/asmopt/$fname.opt" ]]; then
  cat >> "$_jcl_file" << EOF
//COMPILE EXEC ASMA90,HLQ=&HLQ.,MEM=${fname^^},OPT=${fname^^}
EOF
  else
  cat >> "$_jcl_file" << EOF
//COMPILE EXEC ASMA90,HLQ=&HLQ.,MEM=${fname^^},OPT=DEFOPT
EOF
  fi
  cat >> "$_jcl_file" << EOF
//${fname^^} PEND
EOF
# Make job
  local _jcl_file="$1/asmjcl/${fname,,}.jcl"
  cat > "$_jcl_file" << EOF
//${fname^^} JOB 'Compile ${fname^^}',
//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
//*
//LIBSRCH JCLLIB ORDER=${3^^}.ASMJCLP
//*
//COMPILE EXEC ${fname^^},HLQ=${3^^}
EOF
  return 0
}
# Generate compile JCL files
# $1 - project root
# $2 - dsn prefix
function GenProjectCompileJcl() {
  if [[ ( ! -d $1 ) || ( ! $2 ) ]]; then
    return -1
  fi
# Make proc
  local _jcl_file="$1/asmjcl/proc/asmall.jcl"
  cat > "$_jcl_file" << EOF
//ASMALL PROC HLQ=''
//*
//* 'Compile assembler sources'
//*
EOF
  for fn in $(find "$1/asm" -maxdepth 1 -type f -name "*.asm"); do
    GenFileCompileJcl "$1" "$fn" "$2"
    fname="${fn##*/}"
    fname="${fname%%.*}"
    fext="${fn##*.}"
    cat >> "$_jcl_file" << EOF
//${fname^^} EXEC ${fname^^},HLQ=&HLQ.
EOF
  done
  cat >> "$_jcl_file" << EOF
//ASMALL PEND
EOF

# Make job
  local _jcl_file="$1/asmjcl/asmall.jcl"
  cat > "$_jcl_file" << EOF
//ASMALL JOB 'Compile assembler sources',
//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
//*
//LIBSRCH JCLLIB ORDER=${2^^}.ASMJCLP
//*
//V1      SET HLQ=${2^^}
//*
//COMPILE EXEC ASMALL,HLQ=&HLQ.
EOF
  return 0
}

function PrintHelp() {
  echo "MVS SDK Tools 0.0.1"
  echo "HLASM project tool"
  echo ""
  echo "Usage:"
  echo ""
  echo " mvshlasm <command> <options>"
  echo ""
  echo "  Commands:"
  echo "    -n          - Create new HLASM project in root specified by -r option"
  echo "    -g          - Get project files from datasets"
  echo "    -p          - Put project files to datasets"
  echo "    -j          - Generate/Update compile JCLs"
  echo "    -o          - Get assembler outputs after compile"
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
      echo "MVSHLA001E: Invalid parameter $_opt. See -h or --help."
      exit -1
    ;;
  esac
  shift
done
if [[ ("$_action" == "NEW" || "$_action" == "GET" || "$_action" == "PUT" || "$_action" == "OUT" )  && ( -z "$_host" ) ]]; then
  echo "MVSHLA002E: Host name expected for action $_action. See -h or --help."
  exit -1
fi
if [[ ("$_action" == "NEW" || "$_action" == "GET" || "$_action" == "PUT" || "$_action" == "OUT" ) && ( -z "$_user" ) ]]; then
  echo "MVSHLA003E: User name expected for action $_action. See -h or --help."
  exit -1
fi
if [ -z $_path ]; then
  echo "MVSHLA004E: Project root expected. See -h or --help."
  exit -1
fi
if [ -z $_dsn ]; then
  echo "MVSHLA005E: Project dataset prefix expected. See -h or --help."
  exit -1
fi
if [[ ("$_action" == "NEW" || "$_action" == "GET" || "$_action" == "PUT" || "$_action" == "OUT" ) && ( -z "$_password" ) ]]; then
  read -s -p "Enter password for $_user@$_host: " _password
  echo ""
  if [ -z "$_password" ]; then
    echo "MVSHLA006E: MVS user password expected. See -h or --help."
    exit -1
  fi
fi
case $_action in
  ("NEW")
    CreateLocalSpace "$_path"
    GenDefaultJcl "$_path"
    CreateRemoteSpaceInDS "$_host" "$_user" "$_password" "$_dsn"
  ;;
  ("GET")
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASM -d:$_path/asm -m:*.asm
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMMAC -d:$_path/asm/mac -m:*.asm
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMJCL -d:$_path/asmjcl -m:*.jcl
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMJCLP -d:$_path/asmjcl/proc -m:*.jcl
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMOPT -d:$_path/asmopt -m:*.opt
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMLST -d:$_path/asmlst -m:*.lst
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMADATA -d:$_path/asmadata -m:*.adata
#    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMWF -d:$_path/asmwf -m:*.awf
  ;;
  ("PUT")
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/asm -m:*.asm -f:${_dsn^^}.ASM
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/asm/mac -m:*.asm -f:${_dsn^^}.ASMMAC
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/asmjcl -m:*.jcl -f:${_dsn^^}.ASMJCL
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/asmjcl/proc -m:*.jcl -f:${_dsn^^}.ASMJCLP
    ${BASH_SOURCE%/*}/mvsftp.sh -p -h:$_host -u:$_user -s:$_password -d:$_path/asmopt -m:*.opt -f:${_dsn^^}.ASMOPT
  ;;
  ("JCL")
    GenProjectCompileJcl "$_path" "$_dsn"
  ;;
  ("OUT")
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMLST -d:$_path/asmlst -m:*.lst
    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMADATA -d:$_path/asmadata -m:*.adata
#    ${BASH_SOURCE%/*}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASMWF -d:$_path/asmwf -m:*.awf
  ;;
esac
exit 0
