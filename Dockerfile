FROM linuxserver/baseimage:latest

#prepare workdir
ENV WORKDIR /opt/otr
RUN mkdir -p "${WORKDIR}/in" "${WORKDIR}/out" && \
  chmod -R 755 ${WORKDIR}
WORKDIR ${WORKDIR}
ENV PATH $PATH:/"${WORKDIR}"

# install otrtool
RUN apt-get -q update && \
apt-get install -qy build-essential \
  libmcrypt-dev \
  libcurl4-gnutls-dev && \
mkdir -p /tmp/otrtool && \
curl -L 'https://github.com/otrtool/otrtool/archive/master.tar.gz' | tar xvz -C /tmp/otrtool --strip-components=1 && \
cd /tmp/otrtool && \
make && \
cp otrtool ${WORKDIR}

# install multicut_light
RUN apt-get install -qy bc wget dialog libav-tools avidemux-cli && \
curl -L 'https://raw.githubusercontent.com/crushcoder/multicut_light/master/multicut_light_20100518.sh' -o "${WORKDIR}/multicut.sh" && \
chmod 755 "${WORKDIR}/multicut.sh"

# clean
RUN apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# copy config, init and main script
COPY otr-auto.sh ${WORKDIR}
COPY config/ /tmp/otr-config
COPY init/ /etc/my_init.d/
COPY services/ /etc/service/
RUN chmod -v +x /etc/service/*/run /etc/my_init.d/*.sh ${WORKDIR}/*.sh
