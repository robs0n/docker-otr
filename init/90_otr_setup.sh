#!/bin/bash

if [ ! -f "${WORKDIR}/setup.lock" ]
then
  # copy config
  cp -a /tmp/otr-config/. ${WORKDIR}/
  # chown files to running user
  if [ ! -z ${PUID+x} ]
  then
    find ${WORKDIR} ! \( -user abc -a -group abc \) \( -path ${WORKDIR}/in -o -path ${WORKDIR}/out \) -prune -o -print0 | xargs -0 chown abc:abc
  fi
  touch ${WORKDIR}/setup.lock
fi
