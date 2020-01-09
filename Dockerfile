FROM python:3.7-slim-stretch

# Determine environment
ARG BUILD_ENV=prod
ENV BUILD_ENV=$BUILD_ENV

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
    apt-key adv --keyserver keys.gnupg.net --recv-keys E19F5F87128899B192B1A2C2AD5F960A256A04AF && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/' && \
    apt-get update -y -q && \
    apt-get install -y --no-install-recommends \
        r-base && \
    apt-get remove --purge --auto-remove -y gnupg1 software-properties-common curl apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

# Add binaries
ADD /bin /usr/local/bin
RUN chmod -R +x /usr/local/bin

# Specify where the data volume is mounted
VOLUME $GENTB_DATA_PATH

CMD ["R", "--version"]