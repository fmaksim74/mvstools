#!/bin/bash

_mvs_host="rs22.rocketsoftware.com"
_mvs_userid="TS5671"
_mvs_userpw=""

_ws_project_root="$HOME/workspace/mvf0401_spss"

function LoadFiles() {
  mkdir -p "$_ws_project_root/asm"
  mkdir -p "$_ws_project_root/bindjcl"
  mkdir -p "$_ws_project_root/buildjcl"
  mkdir -p "$_ws_project_root/c"
  mkdir -p "$_ws_project_root/ccopt"
  mkdir -p "$_ws_project_root/exp"
  mkdir -p "$_ws_project_root/h"
  mkdir -p "$_ws_project_root/jcl"
  mkdir -p "$_ws_project_root/lmod"
  mkdir -p "$_ws_project_root/settings"
  mkdir -p "$_ws_project_root/sql"

ftp -n -i "$_mvs_host" << End-Of-Session
user "${_mvs_userid,,}" "$_mvs_userpw"
cd "'TSEVG.MVF0401.SPSS.ASM'"
lcd "$_ws_project_root/asm"
mget *
cd "'TSEVG.MVF0401.SPSS.BINDJCL'"
lcd "$_ws_project_root/bindjcl"
mget *
cd "'TSEVG.MVF0401.SPSS.BUILDJCL'"
lcd "$_ws_project_root/buildjcl"
mget *
cd "'TSEVG.MVF0401.SPSS.C'"
lcd "$_ws_project_root/c"
mget *
cd "'TSEVG.MVF0401.SPSS.CCOPT'"
lcd "$_ws_project_root/ccopt"
mget *
cd "'TSEVG.MVF0401.SPSS.H'"
lcd "$_ws_project_root/h"
mget *
cd "'TSEVG.MVF0401.SPSS.JCL'"
lcd "$_ws_project_root/jcl"
mget *
cd "'TSEVG.MVF0401.SPSS.LMOD'"
lcd "$_ws_project_root/lmod"
mget *
cd "'TSEVG.MVF0401.SPSS.SETTINGS'"
lcd "$_ws_project_root/settings"
mget *
cd "'TSEVG.MVF0401.SPSS.SQL'"
lcd "$_ws_project_root/sql"
mget *
by
End-Of-Session

  return 0
}

function RenameFiles() {
  cd "$1"
  for fname in $( find . -maxdepth 1 -type f ! -name "*.*" )
  do
    mv "$fname" "${fname,,}.$2"
  done
  return $?
}

function main() {

  LoadFiles
  RenameFiles "$_ws_project_root/asm" "asm"
  RenameFiles "$_ws_project_root/bindjcl" "jcl"
  RenameFiles "$_ws_project_root/buildjcl" "jcl"
  RenameFiles "$_ws_project_root/c" "cpp"
  RenameFiles "$_ws_project_root/ccopt" "ccopt"
  RenameFiles "$_ws_project_root/exp" "exp"
  RenameFiles "$_ws_project_root/h" "h"
  RenameFiles "$_ws_project_root/jcl" "jcl"
  RenameFiles "$_ws_project_root/lmod" "lmod"
  RenameFiles "$_ws_project_root/settings" "settings"
  RenameFiles "$_ws_project_root/sql" "sql"

  exit 0
}

main
