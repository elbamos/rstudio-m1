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
    cmake \
    curl \
    default-jdk \
    file \
    fonts-roboto \
    fonts-texgyre \
    g++ \
    gdal-bin \
    gfortran \
    ghostscript \
    git \
    gsfonts \
    hugo \
    lbzip2 \
    less \
    libapparmor1 \
    libbz2-*\
    libbz2-dev \
    libclang-dev \
    libcurl4 \
    libcurl4-openssl-dev \
    libedit2 \
    libfftw3-dev \
    libfribidi-dev \
    libgc1c2 \
    libgdal-dev \
    libgeos-dev \
    libgl1-mesa-dev \
    libglpk-dev \
    libglu1-mesa-dev \
    libgmp3-dev \
    libgsl0-dev \
    libharfbuzz-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libhunspell-dev \
    libicu-dev \
    libjq-dev \
    liblzma-dev \
    libmagick++-dev \
    libnetcdf-dev \
    libobjc4 \
    libopenmpi-dev \
    libpangocairo-* \
    libpcre2-dev \
    libpng16* \
    libpq-dev \
    libpq5 \
    libproj-dev \
    libprotobuf-dev \
    libreadline-dev \
    libreadline7 \
    libsqlite3-dev \
    libssl-dev \
    libssl-dev \
    libudunits2-dev \
    libxml2-dev \
    libxslt1-dev \
    libzmq3-dev \
    lsb-release \
    netcdf-bin \
    postgis \
    procps \
    protobuf-compiler \
    psmisc \
    python-setuptools \
    qpdf \
    software-properties-common \
    sqlite3 \
    sudo \
    texinfo \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    tk-dev \
    unixodbc-dev \
    wget

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
       >> /usr/local/lib/R/etc/Rprofile.site

COPY --from=builder /usr/local/src/packages packages
RUN apt-get install -qqy --no-install-recommends libc-ares2 \
  && dpkg -i ./packages/libnghttp2-14_1.36.0-bionic0_arm64.deb \
  && dpkg -i ./packages/libuv1_1.24.1-bionic0_arm64.deb \
  && dpkg -i ./packages/libnode64_10.15.2~dfsg-bionic0_arm64.deb \
  && dpkg -i ./packages/libuv1-dev_1.24.1-bionic0_arm64.deb \
  && dpkg -i ./packages/libnode-dev_10.15.2~dfsg-bionic0_arm64.deb \
  && rm -rf ./packages

RUN Rscript -e "install.packages(c('tidyverse', 'sparklyr', \
  'rmarkdown', 'shiny'))"

EXPOSE 8787
CMD ["/init"]
