FROM opensuse:13.2
MAINTAINER Michal TOMA <toma@nic.fr>

# Test push
# Install basic dependencies
RUN pwd
RUN zypper --non-interactive in make gcc git libopenssl-devel timezone postgresql-server postgresql-devel postgresql perl-DBD-Pg perl-App-cpanminus perl-aliased perl-Module-Install
RUN git config --global http.sslVerify false

# Prepare the PostgrSQL backend
RUN mkdir /postgresql_data
RUN chown postgres:postgres /postgresql_data
USER postgres
RUN initdb -D /postgresql_data
USER root

# Clone Backend and install dependencies
RUN git clone https://github.com/dotse/zonemaster-backend.git
#RUN cd /zonemaster-backend && git checkout tags/v1.0.3
RUN cd /zonemaster-backend && cpanm --installdeps --notest --quiet .

# Clone GUI and install dependencies
RUN git clone https://github.com/dotse/zonemaster-gui.git
#RUN cd /zonemaster-gui && git checkout tags/v1.0.3
RUN cd /zonemaster-gui && cpanm --installdeps --notest --quiet .

# Install the CLI interface
RUN cpanm --quiet Zonemaster::CLI

RUN mkdir /var/log/zonemaster

EXPOSE 50000
EXPOSE 50080
COPY zonemaster_startup.sh /
CMD ["sh", "/zonemaster_startup.sh"]
