# XAO::Web base container image.
#
# In most cases it needs to be extended for specific projects to pull in
# additional software dependencies, set the environment, logging, etc.
#
# Default site demo:
#   docker run -p 8080:80 amaltsev/xao-web
#
# Mount and execute a site from the current directory:
#   docker run -p 8080:80 -v $(pwd):/opt/xao/projects/app amaltsev/xao-web
#------------------------------------------------------------------------------

FROM debian:bookworm-slim

LABEL maintainer="Andrew Maltsev am@ejelta.com"

# Software versions to pull. Use --build-arg to override:
#  docker build --build-arg XAO_WEB_VERSION=1.66 -t xao-web:1.66 .
#
ARG XAO_BASE_VERSION=1.28
ARG XAO_FS_VERSION=1.26
ARG XAO_WEB_VERSION=1.93

# Basic package dependencies
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        make \
        perl \
        cpanminus \
        libwww-perl \
        libssl-dev \
        libmariadb-dev \
        libmariadb3 \
    && \
    rm -rf /var/lib/apt/lists/*

# Perl dependencies and XAO::Web
#
# FIXME: Using system perl, change to plenv!
#
RUN   cpanm -n \
        Carton \
        Plack \
        Plack::Middleware::Debug \
        Starman \
        DBD::MariaDB \
        https://cpan.metacpan.org/authors/id/A/AM/AMALTSEV/XAO-Base-$XAO_BASE_VERSION.tar.gz \
        https://cpan.metacpan.org/authors/id/A/AM/AMALTSEV/XAO-FS-$XAO_FS_VERSION.tar.gz \
        https://cpan.metacpan.org/authors/id/A/AM/AMALTSEV/XAO-Web-$XAO_WEB_VERSION.tar.gz \
        2>&1 \
    && \
    rm -rf /root/.cpanm /usr/local/share/man

# Can't live without this
#
RUN echo "alias l='ls -alh'" >> /etc/profile.d/l-alias.sh

# The default site name, override with:
#   docker run --env XAO_SITE_NAME=yoursite ...
#
# Optionally also mount your site code into container:
#   docker run -v $(pwd):/opt/xao/projects/app
#
ENV XAO_SITE_NAME="app"

# Executing the site. Examples:
#
#   docker run --publish 8080:80 amaltsev/xao-web
#
#   docker run --publish 8080:80 --env PSGI_RUNNER=starman amaltsev/xao-web
#
#   docker run -p 8080:80 -v $(pwd):/opt/xao/projects/app amaltsev/xao-web
#
#   docker run -p 8080:80 -v $(pwd):/opt/xao/projects/mysite --env XAO_SITE_NAME=mysite amaltsev/xao-web
#
#   docker run -p 8080:80 -v $(pwd):/opt/xao/projects/app --env PSGI_RUNNER="carton exec starman" amaltsev/xao-web
#
#   docker run -p 8080:80 -v $(pwd):/opt/xao/projects/app \
#           --env PSGI_BUILDER="carton install" \
#           --env PSGI_RUNNER="carton exec plackup" \
#           --env PSGI_OPTIONS="-R templates,objects" \
#           amaltsev/xao-web
#
# Port 80 is not exposed in the image to make it easier to extend this
# with other port and cmd configurations.
#
# Not using 'exec' on the runner to make it easier to stop it with ^C on
# interactive runs. Plackup itself does not react to ^C.
#
ENV PSGI_BUILDER=""
ENV PSGI_RUNNER="plackup"
ENV PSGI_PORT="80"
ENV PSGI_OPTIONS=""

CMD if [ -d /opt/xao/projects/$XAO_SITE_NAME ]; then cd /opt/xao/projects/$XAO_SITE_NAME; fi; \
    $PSGI_BUILDER; \
    $PSGI_RUNNER \
        --port "$PSGI_PORT" \
        --user nobody \
        --group nobody \
        $PSGI_OPTIONS \
        /opt/xao/handlers/xao.psgi
