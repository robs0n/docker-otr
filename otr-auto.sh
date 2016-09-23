#!/bin/bash
umask 0002

OTRTOOL="${WORKDIR}/otrtool"
OTRDECODER="${WORKDIR}/otrdecoder/otrdecoder"
MUTLICUT="${WORKDIR}/multicutmkv.sh"
INPUT_DIR="${WORKDIR}/in"
TMP_DIR="${INPUT_DIR}/tmp"
DECODED_DIR="${INPUT_DIR}/decoded"
CUT_DIR="${INPUT_DIR}/cut"
ERROR_DIR="${INPUT_DIR}/error"

FB="$(which filebot)"
FB_DEFAULT_ARGS="-script fn:amc --lang de --conflict skip -non-strict --log-file ${WORKDIR}/amc.log --output out/"
FB_ACTION_TEST="--action test"
FB_ACTION_COPY="--action copy"
FB_ACTION_MOVE="--action move"
FB_SCRIPT_ARGS="--def excludeList=${WORKDIR}/amc.txt"
FB_MOVIES_FORMAT="movieFormat=movies/{n}"
FB_SERIES_FORMAT="seriesFormat=tv/{n}/{'Staffel '+s.pad(2)}/{n} - {S00E00} - {t}"
FB_TV_SEARCH_FLAG="ut_label=TV"
FB_MOVIE_SEARCH_FLAG="ut_label=Movie"

# Log message to stdout
log() {
  echo $1
}

init(){
  if [ ! -d $TMP_DIR ]
  then
    mkdir -p $TMP_DIR || (echo "can't create temp directory!" && exit 1)
  fi
  if [ ! -d $DECODED_DIR ]
  then
    mkdir -p $DECODED_DIR || (echo "can't create decoded directory!" && exit 1)
  fi
  if [ ! -d $CUT_DIR ]
  then
    mkdir -p $CUT_DIR || (echo "can't create cut directory!" && exit 1)
  fi
  if [ ! -d $ERROR_DIR ]
  then
    mkdir -p $ERROR_DIR/{decode,cut,rename} || (echo "can't create error directory!" && exit 1)
  fi
}

decode(){
  find "${INPUT_DIR}" -maxdepth 1 -type f -name "*.otrkey" | \
  while read file
  do
    FILENAME=$(basename $file)
    DECODED_FILENAME="${FILENAME%.otrkey}"
    if [ ! -f "$DECODED_DIR/$DECODED_FILENAME" ]
    then
      log "decoding $FILENAME"
      $OTRDECODER -e $OTR_USER -p $OTR_PWD -o $TMP_DIR -i $file
      SUCCESS=$?
      if [ $SUCCESS -eq 0 ]
      then
        log "decoding successfull: $FILENAME"
        mv $TMP_DIR/$DECODED_FILENAME $DECODED_DIR
        rm -f $file
      else
        log "decoding failed: $FILENAME"
        rm -f $TMP_DIR/$DECODED_FILENAME
        mv $file "$ERROR_DIR/decode"
      fi
    else
      log "already decoded: $FILENAME"
      rm -f $file
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
      if [ $SUCCESS -eq 0 ]
      then
        CUT_FILE=$(ls "$CUT_DIR/$FILENAME"*)
        mv "$CUT_FILE" "${CUT_FILE/-cut/}"
        log "cutting successfull: $FILENAME"
        rm -f "$file"
      else
        log "cutting failed: $FILENAME"
        rm -f "$CUT_DIR/$FILENAME"*
        mv "$file" "$ERROR_DIR/cut"
      fi
    else
      log "already cuted: $FILENAME"
      rm -f "$file"
    fi
  done
}

rename(){
  find "${CUT_DIR}" -type f | \
  while read file
  do
    FILENAME=$(basename $file)
    IS_TV=0
    IS_MOVIE=0
    log "testing for tv series: $FILENAME"

    if [[ "$FILENAME" == *S[0-9][0-9]E[0-9][0-9]* ]]; then
      $FB $FB_DEFAULT_ARGS $FB_ACTION_TEST $FB_SCRIPT_ARGS $FB_TV_SEARCH_FLAG "$FB_SERIES_FORMAT" $file
      SUCCESS=$?
      if [ $SUCCESS -eq 0 ]
      then
        IS_TV=1
      fi
    fi

    log "testing for movie: $FILENAME"
    OUTPUT=$($FB $FB_DEFAULT_ARGS $FB_ACTION_TEST $FB_SCRIPT_ARGS $FB_MOVIE_SEARCH_FLAG $FB_MOVIES_FORMAT $file)
    SUCCESS=$?
    if [ $SUCCESS -eq 0 ]
    then
      if [ -z "$(echo $OUTPUT | grep 'The Cut')" ]
      then
        IS_MOVIE=1
      fi
    fi

    if (( $IS_TV ^ IS_MOVIE ))
    then
      if [ $IS_TV -eq 1 ]
      then
        $FB $FB_DEFAULT_ARGS $FB_ACTION_COPY $FB_SCRIPT_ARGS $FB_TV_SEARCH_FLAG "$FB_SERIES_FORMAT" $file
      else
        $FB $FB_DEFAULT_ARGS $FB_ACTION_COPY $FB_SCRIPT_ARGS $FB_MOVIE_SEARCH_FLAG "$FB_MOVIES_FORMAT" $file
      fi
      SUCCESS=$?
      if [ $SUCCESS -eq 0 ]
      then
        log "renaming successfull: $FILENAME"
        rm -f "$file"
      else
        log "renaming failed: $FILENAME"
      fi
    else
      log "file could not clearly determined, move to error: $FILENAME"
      mv "$file" "$ERROR_DIR/rename"
    fi
  done
}

cd $(dirname $0)
while true
do
  log "Start processing..."
  init
  decode
  cut
  rename
  log "Wait for next run..."
  sleep 60
done
