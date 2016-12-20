#!/bin/bash
# Main parameters
# Set this values for current project
_prod_name="prod1"
_mod_name="mod1"
_lang="asm"
_ws_project_root="/home/max/workspace/prj1"
_mvs_host="rs22.rocketsoftware.com"
_mvs_userid="ts5671"

# Global constants
_script_name="MVS Tools"
_script_version="0.0.0.1"
_script_msg_prefix="MVST"

#-------------------------------------------------------------------------------
# Common functions
# GetDSN
# %1 - filename
# %2 - prefix
# %3 - hight level qualifer
function GetDSN() {
  fn="${1%.*}"
  fn="${fn##*/}"
  fe="${1##*.}"
  DSN="$fe($fn)"
  if [ "$2" ]; then
    DSN="$2.$DSN"
    if [ "$3" ]; then
      DSN="$3.$DSN"
    fi
  elif [ "$3" ]; then
    DSN="$3.$DSN"
  fi
  echo "${DSN^^}"
  return 0
}
# GetCmdDSN
# %1 - DSN
function GetCmdDSN() {
#  _res=GetDSN "$1" "$2" "$3"
  echo "\"//'`( GetDSN "$1" "$2" "$3" )`'\""
  return 0
}
#-------------------------------------------------------------------------------
# Sync routine for FTP. Write files to dataset
# $1 - folder name cpp,hpp,lmod and other
# $2 - file type
# $3 - dsn qualifier
function FTPDSPutFolder() {
  if [ ! $1 ] ; then
    return -1
  fi
  if [ ! $2 ] ; then
    return -1
  fi
  if [ ! $3 ] ; then
    return -1
  fi
  _ws_dd="$_ws_tmp/${_prj_prefix^^}.${3^^}"
  if [[ -d "$_ws_dd" ]]; then
    rm -r "$_ws_dd"
  fi
  mkdir -p "$_ws_dd"
  if [ ! $? -eq 0 ] ; then
    echo "Cannot create DD folder in $_ws_dd"
    return -1
  fi
  for fname in $( find "$_ws_project_root/$1" -maxdepth 1 -type f -name "*.$2" ); do
    fn=${fname%.*}
    fn=${fn##*/}
    cp "/$fname" "$_ws_dd/${fn^^}"
    if [ ! $? -eq 0 ] ; then
      echo "Error while coping file from $fname to $_ws_dd/${fn^^}"
    fi
  done
  _mvs_dd="'${_mvs_userid^^}.${_prj_prefix^^}.${3^^}'"
  ftp -n -i "$_mvs_host" << End-Of-Session
user "${_mvs_userid,,}" "$_mvs_userpw"
lcd "$_ws_dd"
cd "$_mvs_dd"
mput *
by
End-Of-Session
  return 0
}
# $1 - folder name cpp,hpp,lmod and other
# $2 - file type
# $3 - dsn qualifier
function FTPDSGetFolder() {
  if [ ! $1 ] ; then
    return -1
  fi
  if [ ! $2 ] ; then
    return -1
  fi
  if [ ! $3 ] ; then
    return -1
  fi
  _ws_dd="$_ws_tmp/${_prj_prefix^^}.${3^^}"
  if [[ -d "$_ws_dd" ]]; then
    rm -r "$_ws_dd"
  fi
  mkdir -p "$_ws_dd"
  if [ ! $? -eq 0 ] ; then
    echo "Cannot create DD folder in $_ws_dd"
    return -1
  fi
  for fname in $( find "$_ws_project_root/$1" -maxdepth 1 -type f -name "*.$2" ); do
    fn=${fname%.*}
    fn=${fn##*/}
    cp "/$fname" "$_ws_dd/${fn^^}"
    if [ ! $? -eq 0 ] ; then
      echo "Error while coping file from $fname to $_ws_dd/${fn^^}"
    fi
  done
  _mvs_dd="'${_mvs_userid^^}.${_prj_prefix^^}.${3^^}'"
  ftp -n -i "$_mvs_host" << End-Of-Session
user "${_mvs_userid,,}" "$_mvs_userpw"
lcd "$_ws_dd"
cd "$_mvs_dd"
mput *
by
End-Of-Session
  return 0
}
#-------------------------------------------------------------------------------
# Create routines
# Functions for new project generation
function CreateAsmLocalProject() {
  echo "Creating Assembler project folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/asm"
  mkdir -p "$_ws_project_root/asm/mac"
  mkdir -p "$_ws_project_root/asmjcl/proc"
  mkdir -p "$_ws_project_root/asmopt"
  mkdir -p "$_ws_project_root/asmlst"
  mkdir -p "$_ws_project_root/adata"
  mkdir -p "$_ws_project_root/asmwf"
  return 0
}
function GenDefaultAsmJcl() {
_jcl_file="$_ws_project_root/asmjcl/proc/asma90.jcl"
cat > "$_jcl_file" << EOF
//ASSEMBLY PROC HLQ='',PROD='',MOD='',MEM='',OPT='DEFOPT'
//*
//DOASSMBL     EXEC PGM=ASMA90,PARM=OBJECT
//SYSIN        DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..ASM(&MEM.)
//SYSLIN       DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..ASMOBJ(&MEM.)
//SYSLIB       DD DISP=SHR,DSN=SYS1.MACLIB
//             DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..ASMMAC
//ASMAOPT      DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..ASMOPT(&OPT.)
//SYSPRINT     DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..ASMLST(&MEM.)
//ASSEMBLY PEND
EOF
return 0
}
# Generate jcl procedure for assembler source file compiling
# $1 - c file name
function GenAsmFileCompileJcl() {
  fname="${1##*/}"
  fname="${fname%%.*}"
  fext="${fn##*.}"
# Gen proc
  _asmfile_jcl="$_ws_project_root/asmjcl/proc/${fname,,}.jcl"
cat > "$_asmfile_jcl" << EOF
//${fname^^} PROC 'Compile ${fname^^}',
//*
//LIBSRCH JCLLIB ORDER=.${_mvs_userid^^}.${_prod_name^^}.${_mod_name^^}.ASMJCLP
//*
EOF
  if [[ -f "$_ws_project_root/asmopt/$fname.opt" ]]; then
cat >> "$_asmfile_jcl" << EOF
//COMPILE EXEC ASMA90,HLQ=$_mvs_userid,PROD=$_prod_name,MOD=$_mod_name,MEM=${fname^^},OPT=${fname^^}
EOF
  else
cat >> "$_asmfile_jcl" << EOF
//COMPILE EXEC ASMA90,HLQ=${_mvs_userid^^},PROD=${_prod_name^^},MOD=${_mod_name^^},MEM=${fname^^}
EOF
  fi
cat >> "$_asmfile_jcl" << EOF
//${fname^^} PEND
EOF

# Make job
  _asmfile_jcl="$_ws_project_root/asmjcl/${fname,,}.jcl"
cat > "$_asmfile_jcl" << EOF
//${fname^^} JOB 'Compile ${fname^^}',
//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
//*
//LIBSRCH JCLLIB ORDER=&HLQ..&PROD..&MOD..ASMJCLP
//*
//COMPILE EXEC ${fname^^}
EOF
  return 0
}
function GenAsmProjectCompileJcl() {
  _asmproj_jcl="$_ws_project_root/asmjcl/asmall.jcl"
cat > "$_asmproj_jcl" << EOF
//ASMALL JOB 'Compile ${_mod_name^^} Assembler sources',
//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
//*
//LIBSRCH JCLLIB ORDER=&HLQ..&PROD..&MOD..ASMJCLP
//*
EOF
  for fn in $(find "$_ws_project_root/asm" -maxdepth 1 -type f -name "*.asm"); do
    GenAsmFileCompileJcl $fn
    fname="${fn##*/}"
    fname="${fname%%.*}"
    fext="${fn##*.}"
cat >> "$_asmproj_jcl" << EOF
//COMPILE EXEC ${fname^^}
EOF
  done
  return 0
}
function CreateAsmRemoteProjectDS() {
sshpass -p "$_mvs_userpw" ssh "${_mvs_userid,,}@$_mvs_host" << End-Of-Session
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASM)      NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASMMAC)   NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASMJCL)   NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASMJCLP)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASMOPT)   NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASMLST)   NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(882)   DIR(1) LRECL(137)   RECFM(V,B,A) DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASMOBJ)   NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32720) DIR(1) LRECL(80)    RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASMADATA) NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(32756) RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.ASMWF)    NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(32756) RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
exit
End-Of-Session
return 0
}
function CreateCLocalProject() {
  echo "Creating C project folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/c"
  mkdir -p "$_ws_project_root/h"
  mkdir -p "$_ws_project_root/cjcl/proc"
  mkdir -p "$_ws_project_root/copt"
  return 0
}
function GenDefaultCJcl() {
  _jcl_file="$_ws_project_root/cjcl/proc/cc.jcl"

cat > "$_jcl_file" << EOF
//CC PROC HLQ='',PROD='',MOD='',MEM='',OPT='DEFOPT'
//*
//DOCC EXEC  PGM=CCNDRVR,PARM='OPTFILE(DD:SYSOPTF)'
//STEPLIB    DD DISP=SHR,DSN=CBC.SCCNCMP
//           DD DISP=SHR,DSN=CEE.SCEERUN
//           DD DISP=SHR,DSN=CEE.SCEERUN2
//SYSIN      DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..C(&MEM.)
//USERLIB    DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..H
//SYSOPTF    DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..COPT(&OPT.)
//SYSLIN     DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..COBJ(&MEM.)
EOF

  if [ -d "$_ws_project_root/bindjcl" ] ; then
cat >> "$_jcl_file" << EOF
//DBRMLIB    DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..DBRM(&MEM.)
EOF
  fi

cat >> "$_jcl_file" << EOF
//SYSCPRT    DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..CLST(&MEM.)
//SYSOUT     DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..CPRN(&MEM.)
//CC PEND
EOF

  return 0
}
# Generate jcl procedure for C source file compiling
# $1 - c file name
function GenCFileCompileJcl() {
  fname="${1##*/}"
  fname="${fname%%.*}"
  fext="${fn##*.}"
# Gen proc
  _cfile_jcl="$_ws_project_root/cjcl/proc/${fname,,}.jcl"
cat > "$_cfile_jcl" << EOF
//${fname^^} PROC 'Compile ${fname^^}',
//*
//LIBSRCH JCLLIB ORDER=.${_mvs_userid^^}.${_prod_name^^}.${_mod_name^^}.CJCLP
//*
EOF
  if [[ -f "$_ws_project_root/copt/$fname.opt" ]]; then
cat >> "$_cfile_jcl" << EOF
//COMPILE EXEC CC,HLQ=$_mvs_userid,PROD=$_prod_name,MOD=$_mod_name,MEM=${fname^^},OPT=${fname^^}
EOF
  else
cat >> "$_cfile_jcl" << EOF
//COMPILE EXEC CC,HLQ=${_mvs_userid^^},PROD=${_prod_name^^},MOD=${_mod_name^^},MEM=${fname^^}
EOF
  fi
cat >> "$_cfile_jcl" << EOF
//${fname^^} PEND
EOF

# Make job
  _cfile_jcl="$_ws_project_root/cjcl/${fname,,}.jcl"
cat > "$_cfile_jcl" << EOF
//${fname^^} JOB 'Compile ${fname^^}',
//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
//*
//LIBSRCH JCLLIB ORDER=&HLQ..&PROD..&MOD..CJCLP
//*
//COMPILE EXEC ${fname^^}
EOF
  return 0
}
function GenCProjectCompileJcl() {
  _cproj_jcl="$_ws_project_root/cjcl/ccall.jcl"
cat > "$_cproj_jcl" << EOF
//CCALL JOB 'Compile ${_mod_name^^} C sources',
//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
//*
//LIBSRCH JCLLIB ORDER=&HLQ..&PROD..&MOD..CJCLP
//*
EOF
  for fn in $(find "$_ws_project_root/c" -type f -name "*.c"); do
    GenCFileCompileJcl $fn
    fname="${fn##*/}"
    fname="${fname%%.*}"
    fext="${fn##*.}"
cat >> "$_cproj_jcl" << EOF
//COMPILE EXEC ${fname^^}
EOF
  done
  return 0
}
function CreateCRemoteProjectDS() {
sshpass -p "$_mvs_userpw" ssh "${_mvs_userid,,}@$_mvs_host" << End-Of-Session
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.C)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.H)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CJCL)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CJCLP) NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.COPT)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPRN)  NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(882)   DIR(1) LRECL(137)  RECFM(V,B,A) DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CLST)  NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(882)   DIR(1) LRECL(137)  RECFM(V,B,A) DSORG(PO) DSNTYPE(LIBRARY,2)"
#tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CEVN)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(4099)  DIR(1) LRECL(4095) RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
#tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CINC)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.COBJ)  NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
exit
End-Of-Session
return 0
}
function CreateCPPLocalProject() {
  echo "Creating C++ project folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/cpp"
  mkdir -p "$_ws_project_root/hpp"
  mkdir -p "$_ws_project_root/cppjcl/proc"
  mkdir -p "$_ws_project_root/cppopt"
  return 0
}
function GenDefaultCPPJcl() {
  _jcl_file="$_ws_project_root/cppjcl/proc/ccpp.jcl"
cat > "$_jcl_file" << EOF
//CCPP PROC HLQ='',PROD='',MOD='',MEM='',OPT='DEFOPT'
//*
//DOCC EXEC  PGM=CCNDRVR,PARM='/CXX OPTFILE(DD:SYSOPTF)'
//STEPLIB    DD DISP=SHR,DSN=CEE.SCEERUN
//           DD DISP=SHR,DSN=CEE.SCEERUN2
//           DD DISP=SHR,DSN=CBC.SCCNCMP
//SYSIN      DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..CPP(&MEM.)
//USERLIB    DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..HPP
//SYSOPTF    DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..CPPOPT(&OPT.)
//SYSLIN     DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..CPPOBJ(&MEM.)
EOF
  if [ -d "$_ws_project_root/bindjcl" ] ; then
cat >> "$_jcl_file" << EOF
//DBRMLIB    DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..DBRMLIB(&MEM.)
EOF
  fi
cat >> "$_jcl_file" << EOF
//SYSCPRT    DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..CPPLST(&MEM.)
//SYSOUT     DD DISP=SHR,DSN=&HLQ..&PROD..&MOD..CPPPRN(&MEM.)
//CCPP PEND
EOF
  return 0
}
# Generate jcl procedure for C++ source file compiling
# $1 - cpp file name
function GenCPPFileCompileJcl() {
  fname="${1##*/}"
  fname="${fname%%.*}"
  fext="${fn##*.}"
# Gen proc
  _cfile_jcl="$_ws_project_root/cppjcl/proc/${fname,,}.jcl"
cat > "$_cfile_jcl" << EOF
//${fname^^} PROC 'Compile ${fname^^}',
//*
//LIBSRCH JCLLIB ORDER=.${_mvs_userid^^}.${_prod_name^^}.${_mod_name^^}.CPPJCLP
//*
EOF
  if [[ -f "$_ws_project_root/cppopt/$fname.opt" ]]; then
cat >> "$_cfile_jcl" << EOF
//COMPILE EXEC CCPP,HLQ=$_mvs_userid,PROD=$_prod_name,MOD=$_mod_name,MEM=${fname^^},OPT=${fname^^}
EOF
  else
cat >> "$_cfile_jcl" << EOF
//COMPILE EXEC CCPP,HLQ=${_mvs_userid^^},PROD=${_prod_name^^},MOD=${_mod_name^^},MEM=${fname^^}
EOF
  fi
cat >> "$_cfile_jcl" << EOF
//${fname^^} PEND
EOF

# Make job
  _cfile_jcl="$_ws_project_root/cppjcl/${fname,,}.jcl"
cat > "$_cfile_jcl" << EOF
//${fname^^} JOB 'Compile ${fname^^}',
//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
//*
//LIBSRCH JCLLIB ORDER=&HLQ..&PROD..&MOD..CPPJCLP
//*
//COMPILE EXEC ${fname^^}
EOF
  return 0
}
function GenCPPProjectCompileJcl() {
  _cproj_jcl="$_ws_project_root/cppjcl/ccppall.jcl"
cat > "$_cproj_jcl" << EOF
//CCALL JOB 'Compile ${_mod_name^^} C++ sources',
//  CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,REGION=0K
//*
//LIBSRCH JCLLIB ORDER=&HLQ..&PROD..&MOD..CPPJCLP
//*
EOF
  for fn in $(find "$_ws_project_root/cpp" -type f -name "*.cpp"); do
    GenCPPFileCompileJcl $fn
    fname="${fn##*/}"
    fname="${fname%%.*}"
    fext="${fn##*.}"
cat >> "$_cproj_jcl" << EOF
//COMPILE EXEC ${fname^^}
EOF
  done
  return 0
}
function CreateCPPRemoteProjectDS() {
sshpass -p "$_mvs_userpw" ssh "${_mvs_userid,,}@$_mvs_host" << End-Of-Session
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPP)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.HPP)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPPJCL)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPPJCLP) NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPPOPT)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPPPRN)  NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(882)   DIR(1) LRECL(137)  RECFM(V,B,A) DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPPLST)  NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(882)   DIR(1) LRECL(137)  RECFM(V,B,A) DSORG(PO) DSNTYPE(LIBRARY,2)"
#tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPPEVN)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(4099)  DIR(1) LRECL(4095) RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
#tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPPINC)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.CPPOBJ)  NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
exit
End-Of-Session
return 0
}
function CreateModuleLocalProject() {
  echo "Creating load module project folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/bldjcl/proc"
  mkdir -p "$_ws_project_root/lopt"
  mkdir -p "$_ws_project_root/lmod"
}
function CreateModuleRemoteProjectDS() {
sshpass -p "$_mvs_userpw" ssh "${_mvs_userid,,}@$_mvs_host" << End-Of-Session
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.BLDJCL)   NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.BLDJCLP)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.LOPT)     NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.LMOD)     NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.LEXP)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.LPRN)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(121)  RECFM(F,B,A) DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.LTRM)     NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.LOADLIB)  NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(U,V)   DSORG(PO) DSNTYPE(LIBRARY,2)"
exit
End-Of-Session
return 0
}
function CreateSQLLocalProject() {
  echo "Creating SQL project folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/sql"
  mkdir -p "$_ws_project_root/sqljcl"
  mkdir -p "$_ws_project_root/sqljcl/proc"
  return 0
}
function CreateSQLRemoteProjectDS() {
sshpass -p "$_mvs_userpw" ssh "${_mvs_userid,,}@$_mvs_host" << End-Of-Session
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.SQL)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(32760) DIR(1) LRECL(255)  RECFM(V,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.SQLJCL)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.SQLJCLP) NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
exit
End-Of-Session
return 0
}
function CreateEmbededSQLLocalProject() {
  echo "Creating Embeded SQL project folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/db2pjcl"
  mkdir -p "$_ws_project_root/db2pjcl/proc"
  mkdir -p "$_ws_project_root/bindjcl"
  mkdir -p "$_ws_project_root/bindjcl/proc"
  return 0
}
function CreateEmbededSQLRemoteProjectDS() {
sshpass -p "$_mvs_userpw" ssh "${_mvs_userid,,}@$_mvs_host" << End-Of-Session
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.DB2PJCL)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.DB2PJCLP) NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.BINDJCL)  NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.BINDJCLP) NEW SPACE(1,5)  TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
tsocmd "ALLOCATE DATASET(${_prj_prefix^^}.DBRM)     NEW SPACE(5,10) TRACKS AVGREC(U) BLKSIZE(800)   DIR(1) LRECL(80)   RECFM(F,B)   DSORG(PO) DSNTYPE(LIBRARY,2)"
exit
End-Of-Session
return 0
}
function CreateDocLocalProject() {
  echo "Creating documentation folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/doc"
  return 0
}

function CreateDoxygenLocalProject() {
  echo "Creating doxygen folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/dxg"
  return 0
}

function CreateDocBookLocalProject() {
  echo "Creating docbook folders in $_ws_project_root ... "
  mkdir -p "$_ws_project_root/dbk"
# TODO Generate docbook config
# TODO Generate docs skeletons
  return 0
}

# Sync routines for ssh
# $1 - folder name cpp,hpp,lmod and other
function SSHFSWorkspaceExist() {
  mkdir -p "$_ws_hfs_mpoint"
  sshpass -p "$_mvs_userpw" sshfs -o reconnect "${_mvs_userid,,}"@"${_mvs_host,,}":"$_mvs_home" "$_ws_hfs_mpoint"
  mkdir -p "$_ws_hfs_mpoint_workspace"
  if [ ! $? -eq 0 ] ; then
    echo "Cannot create a workspace $_ws_hfs_mpoint_workspace."
    return -1
  fi
  return 0
}
function SSHFSProjectRootExist() {
  SSHFSWorkspaceExist
  if [ ! $? -eq 0 ]; then
    return -1
  fi
  mkdir -p "$_ws_hfs_mpoint_project_root"
  if [ ! $? -eq 0 ] ; then
    echo "Cannot create a project root $_ws_hfs_mpoint_project_root."
    return -1
  fi
  return 0
}
function SSHFSSyncFolder() {
  if [ ! $1 ] ; then
    return -1
  fi
  rsync -r -u -t -del "$_ws_project_root/$1" "$_ws_hfs_mpoint_project_root"
  return $?
}
function SSHFSSyncAsmProject() {
  SSHFSProjectRootExist
  if [ ! $? -eq 0 ] ; then
    return -1
  fi
  if [ -d "$_ws_project_root/c" ] ; then
    echo "C project exist. Sync it!"
    SSHFSSyncFolder "asm"
    SSHFSSyncFolder "mac"
    SSHFSSyncFolder "jcl"
    SSHFSSyncFolder "jcl/proc"
    SSHFSSyncFolder "opt"
  fi
  return 0
}
function SSHFSSyncCProject() {
  SSHFSProjectRootExist
  if [ ! $? -eq 0 ] ; then
    return -1
  fi
  if [ -d "$_ws_project_root/c" ] ; then
    echo "C project exist. Sync it!"
    SSHFSSyncFolder "c"
    SSHFSSyncFolder "h"
    SSHFSSyncFolder "copt"
    SSHFSSyncFolder "lopt"
    SSHFSSyncFolder "lmod"
    SSHFSSyncFolder "buildjcl"
  fi
  return 0
}
function SSHFSSyncCPPProject() {
  SSHFSProjectRootExist
  if [ ! $? -eq 0 ] ; then
    return -1
  fi
  if [ -d "$_ws_project_root/cpp" ] ; then
    echo "C++ project exist. Sync it!"
    SSHFSSyncFolder "cpp"
    SSHFSSyncFolder "hpp"
    SSHFSSyncFolder "copt"
    SSHFSSyncFolder "lopt"
    SSHFSSyncFolder "lmod"
    SSHFSSyncFolder "buildjcl"
  fi
  return 0
}
function SSHFSSyncSQLProject() {
  SSHFSProjectRootExist
  if [ ! $? -eq 0 ] ; then
    return -1
  fi
  if [ -d "$_ws_project_root/sql" ] ; then
    echo "SQL project exist. Sync it!"
    SSHFSSyncFolder "sql"
    SSHFSSyncFolder "bindjcl"
    SSHFSSyncFolder "exsqljcl"
  fi
  return 0
}
function SSHFSSyncDocProject() {
  SSHFSProjectRootExist
  if [ ! $? -eq 0 ] ; then
    return -1
  fi
  if [ -d "$_ws_project_root/doc" ] ; then
    echo "Documentation exist. Sync it!"
    SSHFSSyncFolder "doc"
  fi
  return 0
}
function SSHFSSyncDoxygenProject() {
  SSHFSProjectRootExist
  if [ ! $? -eq 0 ] ; then
    return -1
  fi
  if [ -d "$_ws_project_root/dxg" ] ; then
    echo "Doxygen project exist. Sync it!"
    SSHFSSyncFolder "dxg"
  fi
  return 0
}
function SSHFSSyncDocBookProject() {
  SSHFSProjectRootExist
  if [ ! $? -eq 0 ] ; then
    return -1
  fi
  if [ -d "$_ws_project_root/dbk" ] ; then
    echo "DocBook project exist. Sync it!"
    SSHFSSyncFolder "dbk"
  fi
  return 0
}
function SSHFSSyncProject() {
  SSHFSSyncCProject
  SSHFSSyncCPPProject
  SSHFSSyncSQLProject
  SSHFSSyncDocProject
  SSHFSSyncDoxygenProject
  SSHFSSyncDocBookProject
  return 0
}

function FTPDSSyncAsmProject() {
  if [ -d "$_ws_project_root/asm" ] ; then
    echo "Assembler project exist. Sync it!"
    GenAsmProjectCompileJcl
    CreateAsmRemoteProjectDS
    FTPDSPutFolder "asm" "asm" "asm"
    FTPDSPutFolder "asm/mac" "asm" "asmmac"
    FTPDSPutFolder "asmjcl" "jcl" "asmjcl"
    FTPDSPutFolder "asmjcl/proc" "jcl" "asmjclp"
    FTPDSPutFolder "asmopt" "opt" "asmopt"
  fi
  return 0
}
function FTPDSSyncCProject() {
  if [ -d "$_ws_project_root/c" ] ; then
    echo "C project exist. Sync it!"
    GenCProjectCompileJcl
    CreateCRemoteProjectDS
    FTPDSPutFolder "c" "c" "c"
    FTPDSPutFolder "h" "h" "h"
    FTPDSPutFolder "cjcl" "jcl" "cjcl"
    FTPDSPutFolder "cjcl/proc" "jcl" "cjclp"
    FTPDSPutFolder "copt" "opt" "copt"
  fi
  return 0
}
function FTPDSSyncCPPProject() {
  if [ -d "$_ws_project_root/cpp" ] ; then
    echo "C++ project exist. Sync it!"
    GenCPPProjectCompileJcl
    CreateCPPRemoteProjectDS
    FTPDSPutFolder "cpp" "cpp" "cpp"
    FTPDSPutFolder "hpp" "hpp" "hpp"
    FTPDSPutFolder "cppjcl" "jcl" "cppjcl"
    FTPDSPutFolder "cppjcl/proc" "jcl" "cppjclp"
    FTPDSPutFolder "cppopt" "opt" "cppopt"
  fi
  return 0
}
function FTPDSSyncModuleProject() {
  if [ -d "$_ws_project_root/bldjcl" ]; then
    echo "Module project exist. Sync it!"
    CreateModuleRemoteProjectDS
    FTPDSPutFolder "bldjcl" "jcl" "bldjcl"
    FTPDSPutFolder "bldjcl/proc" "jcl" "bldjclp"
    FTPDSPutFolder "lopt" "opt" "lopt"
    FTPDSPutFolder "lmod" "mod" "lmod"
  fi
  return 0
}
function FTPDSSyncSQLProject() {
  if [ -d "$_ws_project_root/sql" ] ; then
    echo "SQL project exist. Sync it!"
    CreateSQLRemoteProjectDS
    FTPDSPutFolder "sql" "sql" "sql"
    FTPDSPutFolder "sqljcl" "jcl" "sqljcl"
    FTPDSPutFolder "sqljcl/proc" "jcl" "sqljclp"
  fi
  return 0
}
function FTPDSSyncEmbededSQLProject() {
  if [ -d "$_ws_project_root/bindjcl" ] ; then
    echo "Embeded SQL project exist. Sync it!"
    CreateEmbededSQLRemoteProjectDS
    FTPDSPutFolder "db2pjcl" "jcl" "db2pjcl"
    FTPDSPutFolder "db2pjcl/proc" "jcl" "db2pjclp"
    FTPDSPutFolder "bindjcl" "jcl" "bindjcl"
    FTPDSPutFolder "bindjcl/proc" "jcl" "bindjclp"
  fi
  return 0
}
# Sync to datasets
function FTPDSSyncProject() {
  FTPDSSyncAsmProject
  FTPDSSyncCProject
  FTPDSSyncCPPProject
  FTPDSSyncModuleProject
  FTPDSSyncSQLProject
  FTPDSSyncEmbededSQLProject
}
function PrintHelp() {
  echo "MVS SDK Tools 0.0.1"
  echo ""
  echo "Usage:"
  echo ""
  echo " mvs.sh <options> <actions>"
  echo ""
  echo "  Options:"
  echo "    -p:product"
  echo "    -m:modname"
  echo "    -l:lang"
  echo "    -r:local_project_root"
  echo "    -h:host"
  echo "    -u:user"
  echo ""
  echo "  Actions:"
  echo "    New project"
  echo "    -n[:<type>]"
  echo "         Create project."
  echo "       Types:"
  echo "       asm  - Assembler project"
  echo "         c  - C project"
  echo "       cpp  - C++ project. Default"
  echo "       sql  - SQL project"
  echo "       esql - Embeded SQL Project"
  echo "       doc  - Documentation folder. Default"
  echo "       dxg  - Doxygen project"
  echo "       dbk  - DocBook project"
  echo "  Sync project:"
  echo "    -s"
  echo "  Sync and compile:"
  echo "    -c"
  echo "  Sync and build:"
  echo "    -b"
}
function ShowVars() {
  echo "_prod_name=$_prod_name"
  echo "_mod_name=$_mod_name"
  echo "_lang=$_lang"

  echo "_mvs_host=$_mvs_host"
  echo "_mvs_userid=$_mvs_userid"
  echo "_mvs_userpw=$_mvs_userpw"

  echo "_mvs_home=$_mvs_home"
  echo "_mvs_project_root=$_mvs_project_root"
  echo "_prj_prefix=$_prj_prefix"

  echo "_ws_project_root=$_ws_project_root"

  echo "_ws_hfs_mpoint=$_ws_hfs_mpoint"
  echo "_ws_hfs_mpoint_workspace=$_ws_hfs_mpoint_workspace"
  echo "_ws_hfs_mpoint_project_root=$_ws_hfs_mpoint_project_root"
  echo "_ws_dd_root=$_ws_dd_root"
  echo "_ws_tmp=$_ws_tmp"
}

##################################################################################################################
# Main routine for any project
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
    ("-b")
      _action="BUILD"
    ;;
    ("-c")
      _action="COMPILE"
    ;;
    ("-p")
      _prod_name="${_opt:3}"
    ;;
    ("-m")
      _mod_name="${_opt:3}"
    ;;
    ("-l")
      _lang="${_opt:3}"
    ;;
    ("-r")
      _ws_project_root="${_opt:3}"
    ;;
    ("-h")
      _mvs_host="${_opt:3}"
    ;;
    ("-u")
      _mvs_userid="${_opt:3}"
    ;;
    ("-n")
      _action="CREATE"
      _prj_types="${_opt:3}"
    ;;
    ("-s")
      _action="SYNC"
    ;;
    (*)
      echo "MVSSDK001E: Invalid parameter $_opt. See -h or --help."
      exit -1
    ;;
  esac
  shift
done
#-----------------------------------------------------------------------------------------------------------------
# Validate parameters
if [[ ! "$_action" ]]; then
  echo "MVSSDK001E: Action expected. See -h or --help."
  exit -1
else
# Product name
  if [[ ! "$_prod_name" ]]; then
    echo "MVSSDK005E: Product name expected. See -h or --help."
    exit -1
  fi
# Module name
  if [[ ! "$_mod_name" ]]; then
    echo "MVSSDK006E: Module name expected. See -h or --help."
    exit -1
  fi
# Lang name
  if [[ ! "$_lang" ]]; then
    echo "MVSSDK001I: Language name expected. Using C++ as default."
  _lang="cpp"
  fi
# Local project root
  if [[ ! "$_ws_project_root" ]]; then
    echo "MVSSDK003E: Local project root expected. See -h or --help."
    exit -1
  fi
# Host name
  if [[ ! "$_mvs_host" ]]; then
    echo "MVSSDK001I: MVS host name expected. Only local structure will be generated. See -h or --help."
  else
# User name
    if [[ ! "$_mvs_userid" ]]; then
      echo "MVSSDK002I: MVS user name expected. Only local structure will be generated. See -h or --help."
    else
      read -s -p "Enter password for $_mvs_userid@$_mvs_host: " _mvs_userpw
      echo ""
      if [[ ! "$_mvs_userpw" ]]; then
        echo "MVSSDK003I: MVS user password expected. Only local structure will be generated. See -h or --help."
      fi
    fi
  fi
#----------------------------------------------------------------------------------------------------------------
# Set internal variables
  _mvs_home="/u/${_mvs_userid,,}"
  _mvs_project_root="$_mvs_home/${_prod_name,,}/${_mod_name,,}"
  _prj_prefix="${_prod_name^^}.${_mod_name^^}"

  _ws_project_root="$_ws_project_root"
  _ws_hfs_mpoint="/tmp/${_mvs_userid,,}"
  _ws_hfs_mpoint_workspace="$_ws_hfs_mpoint/$_prod_name"
  _ws_hfs_mpoint_project_root="$_ws_hfs_mpoint_workspace/${_mod_name,,}"
  _ws_tmp="/tmp/mvs"
#-----------------------------------------------------------------------------------------------------------------
# Exec action
  case "$_action" in
    ("CREATE")
      if [[ ! "$_prj_types" ]]; then
        if [[ "$_lang" ]]; then
          _prj_types=$_lang
        else
          echo "MVSSDK003I: Project type to create expected. Using default project types C++ and Documentation."
          _prj_types="cpp,doc"
        fi
      fi
      IFS=","; _prj_types=(${_prj_types}); unset IFS;
      for prj in "${_prj_types[@]}"; do
        case "$prj" in
          ("asm")
            _asm_prj="Y"
            CreateAsmLocalProject
            GenDefaultAsmJcl
            if [[ -n "$_mvs_userpw" ]]; then
              CreateAsmRemoteProjectDS
            fi
          ;;
          ("c")
            _c_prj="Y"
            CreateCLocalProject
            GenDefaultCJcl

            if [[ -n "$_mvs_userpw" ]]; then
              CreateCRemoteProjectDS
            fi
          ;;
          ("cpp")
            _cpp_prj="Y"
            CreateCPPLocalProject
            GenDefaultCPPJcl

            if [[ -n "$_mvs_userpw" ]]; then
              CreateCPPRemoteProjectDS
            fi
          ;;
          ("sql" | "esql")
            _sql_prj="Y"
            CreateSQLLocalProject
            if [[ -n "$_mvs_userpw" ]]; then
              CreateSQLRemoteProjectDS
            fi
            if [[ $prj == "esql" ]]; then
              CreateEmbededSQLLocalProject
              if [[ -n "$_mvs_userpw" ]]; then
                CreateEmbededSQLRemoteProjectDS
              fi
            fi
          ;;
          ("doc")
            _doc_prj="Y"
            CreateDocLocalProject
          ;;
          ("dxg")
            _dxg_prj="Y"
            CreateDoxygenLocalProject
          ;;
          ("dbk")
            _dbk_prj="Y"
            CreateDocBookLocalProject
          ;;
        esac
      done
      if [[ ("$_asm_prj") || ("$_c_prj") || ("$_cpp_prj") ]]; then
        CreateModuleLocalProject
        if [[ -n "$_mvs_userpw" ]]; then
          CreateModuleRemoteProjectDS
        fi
      fi
    ;;
    ("SYNC")
      echo "Sync projects for $_prod_name.$_mod_name ..."
      FTPDSSyncProject
    ;;
    ("COMPILE")
      echo "Compile project..."
    ;;
    ("BUILD")
      echo "Build project..."
    ;;
  esac
fi
exit 0
