#/!bin/bash
USER="ts5671"
PASS=""
DDNAME=SYNCPRJ.data6

sshpass -p $PASS ssh -q -t $USER@rs22.rocketsoftware.com << EOT
  tsocmd "ALLOCATE DATASET(${DDNAME^^}) NEW SPACE(1,1) BLOCK(200) BLKSIZE(800) DIR(1) LRECL(80) RECFM(F,B) DSORG(PO)"
  exit
EOT
