FROM edgyr/internal-ubuntu-builder:latest AS builder

FROM ubuntu:bionic

COPY --from=builder /usr/local/lib/rstudio-server /usr/local/lib/rstudio-server
COPY --from=builder /usr/local/bin/pandoc /usr/local/bin/pandoc
COPY --from=builder /usr/local/lib/R /usr/local/lib/R
COPY --from=builder /usr/local/bin/R* /usr/local/bin/
COPY --from=builder /usr/local/lib/libRmath.so /usr/local/lib/libRmath.so
COPY --from=builder /usr/local/lib/libRmath.a /usr/local/lib/libRmath.a
COPY --from=builder /usr/local/include /usr/local/include

ENV S6_VERSION=${S6_VERSION:-v1.21.7.0}
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV PATH=/usr/local/lib/rstudio-server/bin:$PATH

ENV DEBIAN_FRONTEND=noninteractive

COPY userconf.sh /etc/cont-init.d/userconf
COPY disable_auth_rserver.conf /etc/rstudio/disable_auth_rserver.conf
COPY pam-helper.sh /usr/local/lib/rstudio-server/bin/pam-helper

RUN apt-get update \
  && apt-get install -qqy --no-install-recommends \
  curl \
  file \
  gdal-bin \
  gfortran \
  gsfonts \
  g++ \
  fonts-roboto \
  fonts-texgyre \
  gsfonts \
  git \
  libbz2-*\
  libcurl4 \
  lbzip2 \
  libfftw3-dev \
  libgdal-dev \
  libgeos-dev \
  libgsl0-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  libhdf4-alt-dev \
  libhdf5-dev \
  libjq-dev \
  libpangocairo-* \
  libpq-dev \
  libpng16* \
  libproj-dev \
  libprotobuf-dev \
  libnetcdf-dev \
  libsqlite3-dev \
  libssl-dev \
  libudunits2-dev \
  lsb-release \
  netcdf-bin \
  postgis \
  protobuf-compiler \
  sqlite3 \
  tk-dev \
  unixodbc-dev \
  wget \
  libapparmor1 \
  libgc1c2 \
  libclang-dev \
  libcurl4-openssl-dev \
  libedit2 \
  libobjc4 \
  libssl-dev \
  libpq5 \
  psmisc \
  procps \
  python-setuptools \
  sudo \
  cmake \
   curl \
   default-jdk \
   fonts-roboto \
   ghostscript \
   hugo \
   less \
   libbz2-dev \
   libglpk-dev \
   libgmp3-dev \
   libfribidi-dev \
   libharfbuzz-dev \
   libhunspell-dev \
   libicu-dev \
   liblzma-dev \
   libmagick++-dev \
   libopenmpi-dev \
   libpcre2-dev \
   libreadline7 \
   libreadline-dev \
   libssl-dev \
   libxml2-dev\
   libxslt1-dev \
   libzmq3-dev \
   qpdf \
   texinfo \
   texlive-fonts-recommended \
   texlive-fonts-extra \
   software-properties-common

RUN mkdir -p /etc/R \
     && mkdir -p /etc/rstudio \
     && mkdir -p /usr/local/lib/R/etc \
     && echo '\n\
       \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
       \n# is not set since a redirect to localhost may not work depending upon \
       \n# where this Docker container is running. \
       \nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
       \n  options(httr_oob_default = TRUE) \
       \n}' >> /usr/local/lib/R/etc/Rprofile.site \
     && echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron \
     && useradd rstudio \
     && echo "rstudio:rstudio" | chpasswd \
   	 && mkdir /home/rstudio \
   	 && chown rstudio:rstudio /home/rstudio \
   	 && addgroup rstudio staff \
     &&  echo 'rsession-which-r=/usr/local/bin/R' >> /etc/rstudio/rserver.conf \
     && echo 'lock-type=advisory' >> /etc/rstudio/file-locks \
     && git config --system credential.helper 'cache --timeout=3600' \
     && git config --system push.default simple \
     && wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-aarch64.tar.gz \
     && tar xzf /tmp/s6-overlay-aarch64.tar.gz -C / \
     && mkdir -p /etc/services.d/rstudio \
     && echo '#!/usr/bin/with-contenv bash \
     		  \n for line in $( cat /etc/environment ) ; do export $line ; done \
             \n exec /usr/local/lib/rstudio-server/bin/rserver --server-daemonize 0' \
             > /etc/services.d/rstudio/run \
     && echo '#!/bin/bash \
             \n /usr/local/lib/rstudio-server/bin/rstudio-server stop' \
             > /etc/services.d/rstudio/finish \
     && mkdir -p /home/rstudio/.rstudio/monitored/user-settings \
     && echo 'alwaysSaveHistory="0" \
             \nloadRData="0" \
             \nsaveAction="0"' \
             > /home/rstudio/.rstudio/monitored/user-settings/user-settings \
     && chown -R rstudio:rstudio /home/rstudio/.rstudio \
     && mkdir -p /var/run/rstudio-server \
     && mkdir -p /var/lock/rstudio-server \
     && mkdir -p /var/log/rstudio-server \
     && mkdir -p /var/lib/rstudio-server \
     && cp /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /etc/init.d/ \
     && update-rc.d rstudio-server defaults \
     && ln -f -s /usr/local/lib/rstudio-server/bin/rstudio-server /usr/sbin/rstudio-server \
     && useradd -r rstudio-server \
     && cd .. \
     && rm -rf src \
     && echo "options(repos = c(CRAN='https://cran.rstudio.com'), download.file.method = 'libcurl')" \
       >> /usr/local/lib/R/etc/Rprofile.site \
     && Rscript -e "install.packages(c('tidyverse', 'rstan', 'sparklyr', 'rmarkdown', 'shiny'))"


EXPOSE 8787
CMD ["/init"]
