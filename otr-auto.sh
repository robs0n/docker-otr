#!/bin/bash
umask 0002

OTRTOOL="${WORKDIR}/otrtool"
MUTLICUT="${WORKDIR}/multicutmkv.sh"
INPUT_DIR="${WORKDIR}/in"
TMP_DIR="${INPUT_DIR}/tmp"
DECODED_DIR="${INPUT_DIR}/decoded"
CUT_DIR="${INPUT_DIR}/cut"

# Log message to stdout
log() {
  echo $1
}

init(){
  if [ ! -d $TMP_DIR ]
  then
    mkdir $TMP_DIR || (echo "can't create temp directory!" && exit 1)
  fi
  if [ ! -d $DECODED_DIR ]
  then
    mkdir $DECODED_DIR || (echo "can't create decoded directory!" && exit 1)
  fi
  if [ ! -d $CUT_DIR ]
  then
    mkdir $CUT_DIR || (echo "can't create cut directory!" && exit 1)
  fi
}

decode(){
  find "${INPUT_DIR}" -type f -name "*.otrkey" | \
  while read file
  do
    FILENAME=$(basename $file)
    DECODED_FILENAME="${FILENAME%.otrkey}"
    if [ ! -f "$DECODED_DIR/$DECODED_FILENAME" ]
    then
      log "decoding $FILENAME"
      $OTRTOOL -x -e $OTR_USER -p $OTR_PWD -D $DECODED_DIR "$file"
      SUCCESS=$?
      if [ "$SUCCESS" -eq 0 ]
      then
        log "decoding successfull: $FILENAME"
      else
        log "decoding failed: $FILENAME"
      fi
    else
      log "already decoded: $FILENAME"
    fi
  done
}

cut(){
  find "${DECODED_DIR}" -type f -name "*.avi" | \
  while read file
  do
    FILENAME=$(basename $file)
    if [ ! -f "$CUT_DIR/$FILENAME"* ]
    then
      log "cutting: $FILENAME"
      $MUTLICUT -q -t $TMP_DIR -o $CUT_DIR "$file"
      SUCCESS=$?
      if [ "$SUCCESS" -eq 0 ]
      then
        #rm "$file"
        log "cutting successfull: $FILENAME"
      else
        log "cutting failed: $FILENAME"
      fi
    else
      log "already cuted: $FILENAME"
    fi
  done
}

rename(){
  log "rename"
}

cd $(dirname $0)
while true
do
  log "Start processing..."
  init
  decode
  cut
  rename

  sleep 600
done
