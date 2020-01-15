FROM python:3.7-slim-stretch

# Determine environment
ARG BUILD_ENV=prod
ENV DBMI_ENV=$BUILD_ENV

ARG GENTB_DATA_PATH=/mnt/data
ENV GENTB_DATA_PATH=$GENTB_DATA_PATH

############################################################################
# R
################################################################################
RUN apt-get update && \
    apt-get install --no-install-suggests -y \
        software-properties-common \
        curl \
        gnupg1 \
        apt-transport-https \
        ca-certificates && \
    ( \
        for key in E19F5F87128899B192B1A2C2AD5F960A256A04AF ; \
        do \
            apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
            apt-key adv --keyserver pgp.mit.edu --recv-keys "$key" || \
            apt-key adv --keyserver keyserver.pgp.com --recv-keys "$key" || \
            apt-key adv --keyserver keys.gnupg.net --recv-keys "$key" || \
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key" ; \
        done \
    )  && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/' && \
    apt-get update -y -q && \
    apt-get install -y --no-install-recommends \
        r-base && \
    apt-get remove --purge --auto-remove -y gnupg1 software-properties-common curl apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

# Add binaries
ADD /bin /usr/local/bin
RUN chmod -R +x /usr/local/bin

CMD ["R", "--version"]