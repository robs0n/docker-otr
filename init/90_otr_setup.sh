#!/bin/bash

if [ ! -f "${WORKDIR}/setup.lock" ]
then
  # copy config
  cp -a /tmp/otr-config/. ${WORKDIR}/

  # create cutlist config for multicut
  if [ ! -f "${WORKDIR}/.cutlist.at" ] && [ -n ${CUTLIST_AT_URL} ]
  then
    echo ${CUTLIST_AT_URL} > ${WORKDIR}/.cutlist.at
  fi

  # chown files to running user
  if [ ! -z ${PUID+x} ]
  then
    usermod -d "${WORKDIR}" abc
    find ${WORKDIR} ! \( -user abc -a -group abc \) \( -path ${WORKDIR}/in -o -path ${WORKDIR}/out \) -prune -o -print0 | xargs -0 chown abc:abc
  else
    ln -s ${WORKDIR}/.cutlist.at ~/.cutlist.at
  fi

  touch ${WORKDIR}/setup.lock
fi
