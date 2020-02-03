FROM python:2.7-slim-stretch

# Determine environment
ARG BUILD_ENV=prod
ENV DBMI_ENV=$BUILD_ENV

ARG GENTB_BIN_PATH=/mnt/gentb/bin
ENV GENTB_BIN_PATH=$GENTB_BIN_PATH

ARG GENTB_DATA_PATH=/mnt/gentb/data
ENV GENTB_DATA_PATH=$GENTB_DATA_PATH


################################################################################
# Perl and other packages
################################################################################
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        perl \
        curl \
        wget \
        bzip2 && \
    savedPackages="curl wget bzip2 perl" && \
    apt-mark manual $savedPackages && \
    apt-get auto-remove && \
    rm -rf /var/lib/apt/lists/*

###############################################################################
# R
###############################################################################
RUN apt-get update && \
    apt-get install --no-install-suggests -y \
        software-properties-common \
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
    apt-get remove --purge --auto-remove -y gnupg1 software-properties-common apt-transport-https && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i '/stretch-cran35/{s/^/#/}' /etc/apt/sources.list

WORKDIR /tmp

################################################################################
# Samtools and HTSlib
################################################################################
# Build HTSLib
ENV HTSLIB_VERSION=1.10.2
RUN apt-get update && \
    apt-get install --no-install-suggests -y \
        build-essential \
        autoconf \
        libcurl4-gnutls-dev \
        libbz2-dev \
        liblzma-dev \
        zlib1g-dev && \
    ( \
        wget https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2  && \
        mkdir /tmp/htslib && \
        tar xjf htslib-${HTSLIB_VERSION}.tar.bz2 -C /tmp/htslib --strip-components=1 && \
        cd htslib && \
        autoconf && \
        ./configure && \
        make && \
        make install && \
        rm -rf /tmp/htslib* \
    ) && \
    savedPackages="libcurl4-gnutls-dev libbz2-dev liblzma-dev zlib1g-dev" && \
    apt-mark manual $savedPackages && \
    apt-get remove --purge --auto-remove -y \
        build-essential \
        autoconf && \
    rm -rf /var/lib/apt/lists/*

# Build Samtools
ENV SAMTOOLS_VERSION=1.10
RUN apt-get update && \
    apt-get install --no-install-suggests -y \
        build-essential \
        autoconf \
        libncurses5-dev \
        zlib1g-dev && \
    ( \
        wget https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2  && \
        mkdir /tmp/samtools && \
        tar xjf samtools-${SAMTOOLS_VERSION}.tar.bz2 -C /tmp/samtools --strip-components=1 && \
        cd samtools && \
        autoconf && \
        ./configure --prefix=/usr/local && \
        make && \
        make install && \
        rm -rf /tmp/samtools* \
    ) && \
    savedPackages="libncurses5-dev zlib1g-dev" && \
    apt-mark manual $savedPackages && \
    apt-get remove --purge --auto-remove -y \
        build-essential \
        autoconf && \
    rm -rf /var/lib/apt/lists/*

################################################################################
# Platypus
################################################################################
# Build Platypus
RUN apt-get update && \
    apt-get install --no-install-suggests -y \
        build-essential \
        zlib1g-dev && \
    ( \
        wget https://www.well.ox.ac.uk/files-library/platypus-latest.tgz && \
        mkdir /usr/lib/python2.7/dist-packages/platypus && \
        tar xf platypus-latest.tgz -C /usr/lib/python2.7/dist-packages/platypus --strip-components=1 && \
        cd /usr/lib/python2.7/dist-packages/platypus && \
        ./buildPlatypus.sh && \
        chmod +x /usr/lib/python2.7/dist-packages/platypus/Platypus.py && \
        ln -s /usr/lib/python2.7/dist-packages/platypus/Platypus.py /usr/local/bin/platypus && \
        rm -rf /tmp/platypus* \
    ) && \
    savedPackages="zlib1g-dev" && \
    apt-mark manual $savedPackages && \
    apt-get remove --purge --auto-remove -y \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

################################################################################
# Stampy
################################################################################
# Build Stampy
RUN apt-get update && \
    apt-get install --no-install-suggests -y \
        build-essential && \
    ( \
        wget https://www.well.ox.ac.uk/files-library/stampy-latest.tgz && \
        mkdir /usr/lib/python2.7/dist-packages/stampy && \
        tar xf stampy-latest.tgz -C /usr/lib/python2.7/dist-packages/stampy --strip-components=1 && \
        cd /usr/lib/python2.7/dist-packages/stampy && \
        make && \
        chmod +x /usr/lib/python2.7/dist-packages/stampy/stampy.py && \
        ln -s /usr/lib/python2.7/dist-packages/stampy/stampy.py /usr/local/bin/stampy && \
        rm -rf /tmp/stampy* \
    ) && \
    apt-get remove --purge --auto-remove -y \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

################################################################################
# Other files/binaries
################################################################################
ADD /bin ${GENTB_BIN_PATH}
RUN chmod -R +x ${GENTB_BIN_PATH}

# Compile spogilotype_info
RUN apt-get update && \
    apt-get install --no-install-suggests -y \
        build-essential && \
    ( \
        cd ${GENTB_BIN_PATH}/spoligotype && \
        g++ -std=c++0x spoligotype_info.cpp -o spoligotype_info \
    ) && \
    apt-get remove --purge --auto-remove -y \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

# Add to path
ENV PATH=${PATH}:${GENTB_BIN_PATH}