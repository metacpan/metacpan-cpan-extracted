FROM debian:stretch

# Creates continuous-delivery-template user and group inside container
RUN useradd -ms /bin/bash continuous-delivery-template

# Set the working directory to /home/continuous-delivery-template
WORKDIR /home/continuous-delivery-template

# Copy the current directory contents into the container at /home/continuous-delivery-template
ADD . /home/continuous-delivery-template

# Install any needed packages running development-setup.sh script
RUN apt-get -y update && apt-get -y install libdist-zilla-perl cpanminus git make

# Define continuous-delivery-template user as owner of all files under /home/continuous-delivery-template
RUN chown -R continuous-delivery-template:continuous-delivery-template /home/continuous-delivery-template

# Switch from root user to continuous-delivery-template user
USER continuous-delivery-template:continuous-delivery-template

# Add continuous-delivery-template bin to $PATH
ENV PATH $PATH:/home/continuous-delivery-template/bin

# Install local::lib using cpanminus
RUN cpanm --local-lib=~/perl5 local::lib

# Add ~/perl5 to $PERL5LIB
ENV PERL5LIB $PERL5LIB:/home/continuous-delivery-template/perl5/lib/perl5

# Install Dist::Zilla dependencies from CPAN using cpanminus
RUN dzil authordeps --missing | cpanm --notest
RUN dzil listdeps --missing | cpanm --notest

# By default show the continuous-delivery-template version
CMD ./bin/continuous-delivery-template
