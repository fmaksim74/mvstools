#!/bin/bash
_fname=testasm.hlasm
_lnum=1
_line_width=80
cat $_fname | while IFS= read _line; do
  while [[ ${#_line} -lt $_line_width ]]; do  
    _line="$_line "
  done
  while [[ ${#_line} -gt $_line_width ]]; do
    _line=$( echo "$_line" | rev | sed 's/  / /' | rev )
  done
  echo -n "$_line" | iconv -f UTF-8 -t CP037 >> "$_fname.res" 
  ((_lnum++))	
done
echo "$_res."
