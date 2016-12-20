#/!bin/bash
USER="ts5671"
PASS=""

ftp -n << EOT
open rs22.rocketsoftware.com
user $USER $PASS
nlist
nlist /u/ts5671
by
EOT