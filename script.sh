#!/bin/bash
echo "Hi!"
fn="/dir/file"
echo "Path=${fn%/*}"
echo "Name=${fn##*/}"
echo "Ext=${fn##*.}"
fn=${fn##*/}
echo "Name only=${fn%%.*}"
echo $BASH_VERSINFO

var="*.abc"
echo "${var##*.}"
echo $0
echo ${0%/*}
_path=$(pwd -P)
echo $_path
echo "${BASH_SOURCE%/*}"
exit 0
