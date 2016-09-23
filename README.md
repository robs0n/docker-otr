# docker-otr

docker run -d --name=otr --restart=unless-stopped -v /data/downloads/otr:/opt/otr/in -v /data/videos:/opt/otr/out -e OTR_USER=<USER> -e OTR_PWD=<PDW> -e PUID=<UID> -e PGID=<GID> -e TZ="Europe/Berlin" otr
