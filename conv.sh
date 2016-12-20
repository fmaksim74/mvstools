iconv -f CP037 -t UTF-8 MVF00763 | sed -r "s/(.{80})/\1\n /g"
