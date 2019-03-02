FROM openjdk:8
LABEL maintainer="self@2m.lt"

ENV dbfile ""
ENV username ""
ENV password ""
ENV b2bucket ""
ENV b2appkeyid ""
ENV b2appkey ""

RUN apt-get update
RUN apt-get --assume-yes install man

RUN cd /usr/local/bin && curl -Lo coursier https://git.io/coursier-cli && chmod +x coursier
RUN coursier bootstrap \
  --main-class org.h2.tools.Script \
  --standalone \
  --output /usr/local/bin/h2script \
  -J-Xmx512m \
  com.h2database:h2:1.4.197 

RUN curl https://rclone.org/install.sh | bash

ADD .rclone.conf /root/

VOLUME /data

ENTRYPOINT \
  sed --in-place "s/b2appkeyid/${b2appkeyid}/g" /root/.rclone.conf && \
  sed --in-place "s/b2appkey/${b2appkey}/g" /root/.rclone.conf && \
  h2script \
    -url jdbc:h2:/data/${dbfile} \
    -user ${username} \
    -password ${password} \
    -script /root/${dbfile}.zip \
    -options compression zip \
    && \
  rclone move --progress --stats-one-line /root/${dbfile}.zip remote:${b2bucket}
