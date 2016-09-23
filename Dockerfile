FROM linuxserver/baseimage:latest

#prepare workdir
ENV WORKDIR /opt/otr
RUN mkdir -p "${WORKDIR}/in" "${WORKDIR}/out" && \
  chmod -R 755 ${WORKDIR}
WORKDIR ${WORKDIR}
ENV PATH $PATH:/"${WORKDIR}"

# install otrtool
RUN apt-get -q update && \
apt-get -qy install build-essential \
  libmcrypt-dev \
  libcurl4-gnutls-dev && \
mkdir -p /tmp/otrtool && \
curl -L 'https://github.com/otrtool/otrtool/archive/master.tar.gz' | tar xvz -C /tmp/otrtool --strip-components=1 && \
cd /tmp/otrtool && \
make && \
cp otrtool ${WORKDIR}

# install multicut_light
# RUN apt-get install -qy bc wget dialog libav-tools avidemux-cli && \
# curl -L 'https://raw.githubusercontent.com/crushcoder/multicut_light/master/multicut_light_20100518.sh' -o "${WORKDIR}/multicut.sh" && \
# chmod 755 "${WORKDIR}/multicut.sh"

# install multicutmkv and dependencies
COPY multicutmkv.sh ${WORKDIR}
RUN apt-get -qy install \
  gawk \
  bc \
  wget \
  mediainfo \
  realpath \
  mkvtoolnix \
  ffmsindex \
  x264 \
  build-essential \
  checkinstall \
  git \
  pkg-config \
  yasm \
  autoconf \
  automake \
  libtool \
  mplayer \
  liblog4cpp5-dev \
  liblog4cpp5 \
  libcairo2-dev \
  libpango1.0-dev \
  libjpeg-dev \
  libffms2-dev \
  libavcodec-dev \
  libavformat-dev \
  libavutil-dev \
  libpostproc-dev \
  libswscale-dev && \
  cd /tmp && git clone https://github.com/avxsynth/avxsynth.git && cd avxsynth/ && \
  autoreconf -i && ./configure && make && make install

#install java
RUN mkdir /opt/java && \
  curl -H "Cookie: oraclelicense=accept-securebackup-cookie" \
  -L "http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jre-8u102-linux-x64.tar.gz" | \
  tar xvz -C /opt/java --strip-components=1 && \
  update-alternatives --install "/usr/bin/java" "java" "/opt/java/bin/java" 1 && \
  update-alternatives --install "/usr/bin/javaws" "javaws" "/opt/java/bin/javaws" 1 && \
  update-alternatives --set "java" "/opt/java/bin/java" && \
  update-alternatives --set "javaws" "/opt/java/bin/javaws"

# install filebot
RUN curl -L "http://downloads.sourceforge.net/project/filebot/filebot/FileBot_4.7.2/filebot_4.7.2_amd64.deb?r=&use_mirror=netcologne" -o /tmp/filebot_4.7.2_amd64.deb && \
  dpkg -i /tmp/filebot_4.7.2_amd64.deb

# install otrdecoder
RUN mkdir -p ${WORKDIR}/otrdecoder && \
  curl -L "http://www.onlinetvrecorder.com/downloads/otrdecoder-bin-x86_64-unknown-linux-gnu-0.4.1132.tar.bz2" | \
  tar xvj -C ${WORKDIR}/otrdecoder --strip-components=1

# clean
RUN apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# copy config, init and main script
COPY otr-auto.sh ${WORKDIR}
COPY config/ /tmp/otr-config
COPY init/ /etc/my_init.d/
COPY services/ /etc/service/
RUN chmod -v +x /etc/service/*/run /etc/my_init.d/*.sh ${WORKDIR}/*.sh
