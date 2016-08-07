#!/bin/bash
umask 0002

OTRTOOL="${WORKDIR}/otrtool"
MUTLICUT="${WORKDIR}/multicut.sh"
INPUTDIR="${WORKDIR}/in"
UNCUTDIR="${INPUTDIR}/uncut"

# Log message to stdout and log file
log() {
  echo $1
}

init(){
  if [ ! -d $UNCUTDIR ]
  then
    mkdir $UNCUTDIR || (echo "can't create temp directory!" && exit 1)
  fi
}

decode(){
  find "${INPUTDIR}" -type f -name "*.otrkey" | \
  while read file
  do
    FILENAME=$(basename $file)
    DECODED_FILENAME="${FILENAME%.otrkey}"
    if [ ! -f "$UNCUTDIR/$DECODED_FILENAME" ]
    then
      log "decoding $FILENAME"
      $OTRTOOL -x -e $OTR_USER -p $OTR_PWD -D $UNCUTDIR "$file"
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
  cd "$INPUTDIR" # need to do this for multicut :/
  find . -type f -name "*.avi" | \
  while read file
  do
    FILENAME=$(basename $file)
    log "cutting: $FILENAME"
    $MUTLICUT -auto -smart -remote "$file"
    SUCCESS=$?
    if [ "$SUCCESS" -eq 0 ]
    then
      #rm "$file"
      log "cutting successfull: $FILENAME"
    else
      log "cutting failed: $FILENAME"
    fi
  done
}

rename(){

}

while true
do
  log "Start processing..."
  init
  decode
  cut
  rename
  
  sleep 600
done
