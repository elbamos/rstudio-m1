FROM edgyr/internal-ubuntu-builder:latest

ENV S6_VERSION=${S6_VERSION:-v1.21.7.0}
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV PATH=/usr/local/lib/rstudio-server/bin:$PATH

RUN mkdir -p /etc/R \
  && mkdir -p /etc/rstudio \
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
  ## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package
  &&  echo 'rsession-which-r=/usr/local/bin/R' >> /etc/rstudio/rserver.conf \
  ## use more robust file locking to avoid errors when using shared volumes:
  && echo 'lock-type=advisory' >> /etc/rstudio/file-locks \
  && git config --system credential.helper 'cache --timeout=3600' \
    && git config --system push.default simple \
    ## Set up S6 init system
    && wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-aarch64.tar.gz \
    && tar xzf /tmp/s6-overlay-aarch64.tar.gz -C / \
  && mkdir -p /etc/services.d/rstudio \
  && echo '#!/usr/bin/with-contenv bash \
          \n## load /etc/environment vars first: \
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

COPY userconf.sh /etc/cont-init.d/userconf
COPY disable_auth_rserver.conf /etc/rstudio/disable_auth_rserver.conf
COPY pam-helper.sh /usr/local/lib/rstudio-server/bin/pam-helper

EXPOSE 8787
CMD ["/init"]
