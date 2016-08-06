FROM linuxserver/baseimage:latest

#prepare workdir
ENV WORKDIR /opt/otr
RUN mkdir -p "${WORKDIR}/in" "${WORKDIR}/out" "${WORKDIR}/tmp" && \
chmod -R 755 ${WORKDIR}
WORKDIR ${WORKDIR}
ENV PATH $PATH:/"${WORKDIR}"

# install otrtool
RUN apt-get -q update && \
apt-get install -qy build-essential libmcrypt-dev libcurl4-gnutls-dev && \
mkdir -p /tmp/otrtool && \
curl -L 'https://github.com/otrtool/otrtool/archive/master.tar.gz' | tar xvz -C /tmp/otrtool --strip-components=1 && \
cd /tmp/otrtool && \
make && \
cp otrtool ${WORKDIR}

# install multicutmkv
RUN apt-get install -qy gawk bc mediainfo avidemux-cli && \
curl -L 'https://raw.githubusercontent.com/Jonny007-MKD/multicutmkv/master/multicutmkv.sh' -o "${WORKDIR}/multicutmkv.sh" && \
chmod 755 "${WORKDIR}/multicutmkv.sh"

# install saneRenamix
RUN apt-get install -qy wget && \
curl -L 'https://raw.githubusercontent.com/Jonny007-MKD/OTR-SaneRename/master/saneRenamix.sh' -o "${WORKDIR}/saneRenamix.sh" && \
chmod 755 "${WORKDIR}/saneRenamix.sh"

# install otrDecodeAll
COPY config/otrDecodeAll.config /opt/otr/config
RUN curl -L 'https://raw.githubusercontent.com/Jonny007-MKD/OTR-DecodeAll/master/otrDecodeAll' -o "${WORKDIR}/otrDecodeAll.sh" && \
chmod 755 "${WORKDIR}/otrDecodeAll.sh"

# clean
RUN apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
