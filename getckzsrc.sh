#!/bin/bash
_mvstools="/home/max/dvlp/mvstools.aws/"
_host="rs22.rocketsoftware.com"
_user="ts5671"
_password="f450j2k"

_dsn="PDBURTS.DVLP.CKZ0301"
_path="/home/max/dvlp/hlasm.aws/ckz/ckz0301/"
mkdir -p $_path/asm/mac
${_mvstools}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASM -d:$_path/asm -m:*.asm
${_mvstools}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.MACLIB -d:$_path/asm/mac -m:*.asm

_dsn="PDBURTS.DVLP.CKZ0301.CKZ2539"
_path="/home/max/dvlp/hlasm.aws/ckz/ckz0301/ckz2539/"
mkdir -p $_path/asm/mac
${_mvstools}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASM -d:$_path/asm -m:*.asm
${_mvstools}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.MACLIB -d:$_path/asm/mac -m:*.asm

_dsn="PDBURTS.DVLP.CKZ0302"
_path="/home/max/dvlp/hlasm.aws/ckz/ckz0302/"
mkdir -p $_path/asm/mac
${_mvstools}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASM -d:$_path/asm -m:*.asm
${_mvstools}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.MACLIB -d:$_path/asm/mac -m:*.asm

_dsn="PDBURTS.DVLP.MVF0303"
_path="/home/max/dvlp/hlasm.aws/mvf/mvf0303/"
mkdir -p $_path/asm/mac
${_mvstools}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.ASM -d:$_path/asm -m:*.asm
${_mvstools}/mvsftp.sh -g -h:$_host -u:$_user -s:$_password -f:${_dsn^^}.MACLIB -d:$_path/asm/mac -m:*.asm
mkdir -p $_path/asm/mac
