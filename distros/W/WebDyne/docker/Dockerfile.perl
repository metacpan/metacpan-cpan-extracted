#  
# WebDyne docker image for Fedora
#
# ====
#
# Override with --build-arg
#
ARG BASE=perl:latest
ARG PORT=8080
ARG WORKERS=8


# Metadata - maintainer
#
#ARG LABEL_MAINTAINER="Andrew Speer <andrew.speer@isolutions.com.au>"
#ARG LABEL_TITLE="WebDyne"
#ARG LABEL_DESCRIPTION="PSGI web service for generating dynamic HTML pages with embedded Perl"
#ARG LABEL_URL="https://github.com/aspeer/WebDyne"
#ARG LABEL_SOURCE="https://github.com/aspeer/WebDyne.git"
#ARG LABEL_DOCUMENTATION="https://github.com/aspeer/WebDyne#readme"
#ARG LABEL_AUTHORS="Andrew Speer <andrew.speer@isolutions.com.au>"
#ARG LABEL_LICENSES="Perl"
#ARG LABEL_CREATED="2025-05-21T10:00:00Z"
#ARG LABEL_VERSION="2.005_225"
#ARG LABEL_REVISION="079c3e1"


# Default paths
#
ARG PERL_CARTON_PATH="/opt/webdyne"
ARG DOCUMENT_ROOT="/app"


# ====
#
# Build stages
#


# Using Fedora as base
#
FROM ${BASE} AS builder


# Redeclare ARGS
#
ARG PERL_CARTON_PATH


# Install build tools and core Perl modules
#

# Nothing to do everything installed



#  Install Carton
#
RUN cpanm --notest Carton


# Set up environment for local::lib
#
RUN echo "PATH ${PATH} $PATH"
ENV PERL_CARTON_PATH=${PERL_CARTON_PATH}
ENV PERL_LOCAL_LIB_ROOT=${PERL_CARTON_PATH}
ENV PERL_MB_OPT="--install_base ${PERL_CARTON_PATH}"
ENV PERL_MM_OPT="INSTALL_BASE=${PERL_CARTON_PATH}"
ENV PERL5LIB=${PERL_CARTON_PATH}/lib/perl5
ENV PATH=${PERL_CARTON_PATH}/bin:$PATH


# Set up app
#
WORKDIR /app


# Checkout Webdyne. Used if cloning
#
#RUN git clone -b development --single-branch https://github.com/aspeer/WebDyne.git pm-WebDyne
#WORKDIR pm-WebDyne


#  Otherwise copy working repo content
#
COPY . .


# And now install CPAN modules using Carton
#
WORKDIR docker.template
COPY docker/cpanfile docker/cpanfile.snapshot ./
RUN carton install --deployment


# Now install main WebDyne module
#
WORKDIR ..
#RUN carton exec -- cpanm --local-lib-contained=${PERL_CARTON_PATH} .
#RUN carton exec -- cpanm .
RUN set -e; carton exec -- cpanm . || { rc=$?; echo "Build failed:"; find /root/.cpanm/work -name build.log -exec cat {} \;; exit $rc; }

# Clean carton cache and create empty webdyne cache dir
RUN rm -rf ${PERL_CARTON_PATH}/cache
RUN mkdir ${PERL_CARTON_PATH}/cache

# ====================================================================================================
#
# Now generate main image from builder image
#
FROM ${BASE}


# Republish args
#
ARG PERL_CARTON_PATH
ARG PORT
ARG DOCUMENT_ROOT


#  Republish labels
#
ARG LABEL_MAINTAINER
ARG LABEL_TITLE
ARG LABEL_DESCRIPTION
ARG LABEL_URL
ARG LABEL_SOURCE
ARG LABEL_DOCUMENTATION
ARG LABEL_AUTHORS
ARG LABEL_LICENSES
ARG LABEL_CREATED
ARG LABEL_VERSION
ARG LABEL_REVISION
ARG BASE


# Add Labels into meta for image
#
#LABEL maintainer=${LABEL_MAINTAINER}
#LABEL org.opencontainers.image.title=${LABEL_TITLE}
#LABEL org.opencontainers.image.description=${LABEL_DESCRIPTION}
#LABEL org.opencontainers.image.url=${LABEL_URL}
#LABEL org.opencontainers.image.source=${LABEL_SOURCE}
#LABEL org.opencontainers.image.documentation=${LABEL_DOCUMENTATION}
#LABEL org.opencontainers.image.authors=${LABEL_AUTHORS}
#LABEL org.opencontainers.image.licenses=${LABEL_LICENSES}
#LABEL org.opencontainers.image.created=${LABEL_CREATED}
#LABEL org.opencontainers.image.version=${LABEL_VERSION}
#LABEL org.opencontainers.image.revision=${LABEL_REVISION}
#LABEL org.opencontainers.image.base=${BASE}


# Add Labels into meta for image
#
LABEL maintainer="Andrew Speer <andrew.speer@isolutions.com.au>"
LABEL org.opencontainers.image.title="WebDyne"
LABEL org.opencontainers.image.description="PSGI web service for generating dynamic HTML pages with embedded Perl"
LABEL org.opencontainers.image.url="https://github.com/aspeer/WebDyne"
LABEL org.opencontainers.image.source="https://github.com/aspeer/WebDyne.git"
LABEL org.opencontainers.image.documentation="https://github.com/aspeer/WebDyne#readme"
LABEL org.opencontainers.image.authors="Andrew Speer <andrew.speer@isolutions.com.au>"
LABEL org.opencontainers.image.licenses="Artistic-1.0-Perl OR GPL-1.0-or-later"
LABEL org.opencontainers.image.created="2026-01-03T03:00:34Z"
LABEL org.opencontainers.image.version="2.042"
LABEL org.opencontainers.image.revision="d99451a"
LABEL org.opencontainers.image.base=${BASE}


# Base perl
#
# Install build tools and core Perl modules
#

#  No extra packages needed



# Install Carton
#
RUN cpanm --notest Carton


# Set up environment for local::lib
#
ENV PERL_CARTON_PATH=${PERL_CARTON_PATH}
ENV PERL5LIB=${PERL_CARTON_PATH}/lib/perl5
ENV PATH=${PERL_CARTON_PATH}/bin:$PATH


# Only examples go into /app, WebDyne perl modules installed into $PERL_CARTONPATH (/opt/webdyne) 
# by default
#
WORKDIR /app


# Copy CPAN modules from builder + example file
#
COPY --from=builder ${PERL_CARTON_PATH} ${PERL_CARTON_PATH}


# Expose port (default 8080)
#
EXPOSE ${PORT}


# Set document root environment var to the server_time example
#
ENV DOCUMENT_ROOT=${DOCUMENT_ROOT}


# WebDyne environment vars
#
ENV WEBDYNE_CACHE_DN=${PERL_CARTON_PATH}/cache


# Entrypoint script for starting process. Kicks off starman on ${PORT}
#
COPY docker/entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


# Empty cmd, entrypoint script runs "starman --port ${PORT} ${PERL_CARTON_PATH}/bin/webdyne.psgi ${DOCUMENT_ROOT}"
#
CMD []