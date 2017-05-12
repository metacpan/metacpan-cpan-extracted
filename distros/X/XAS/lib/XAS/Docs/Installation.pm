package XAS::Docs::Installation;

our $VERSION = '0.02';

1;

__END__
  
=head1 NAME

XAS::Docs::Installation - how to install the XAS environment

XAS is operations middleware for Perl. It provides standardized methods, 
modules and philosophy for constructing large distributed applications. This 
system is based on production level code.

=head1 GETTING THE CODE

Since the code repository is git based, you can use the following commands:

    # mkdir XAS
    # cd XAS
    # git init
    # git pull http://scm.kesteb.us/git/XAS master

Or you can download the code from CPAN in the following manner:

    # cpan -g XAS
    # tar -xvf XAS-0.08.tar.gz
    # cd XAS-0.08

It is suggested that you do not do an automated cpan based install, as it 
will not set up the environment correctly. In either case the following 
commands are run from that directory.

=head1 INSTALLATION

On Unix like systems, using pure Perl, run the following commands:

    # perl Build.PL --installdirs site
    # ./Build
    # ./Build test
    # ./Build install
    # ./Build post_install

If you are DEB based, Debian build files have been provided. If you have a 
Debian build environment, then you can do the following:

    # debian/rules build
    # debian/rules clean
    # dpkg -i ../libxas-perl_0.08-1_all.deb

If you are RPM based, a spec file has been included. If you have a
rpm build environment, then you can do the following:

    # perl Build.PL
    # ./Build
    # ./Build test
    # ./Build dist
    # rpmbuild -ta XAS-0.08.tar.gz
    # cd ~/rpmbuild/RPMS/noarch
    # yum --nogpgcheck localinstall perl-XAS-0.08-1.noarch.rpm

Each of these installation methods will overlay the local file system and
tries to follow Debian standards for file layout and package installation. 

On Windows, do the following:

    > perl Build.PL
    > Build
    > Build test
    > Build install
    > Build post_install

This will create the directory structure C:\XAS. To change this, set the
XAS_ROOT environment variable to something else. This variable should
also be set at the system level. It is recommended that you use 
L<Strawberry Perl|http://strawberryperl.com/>, L<ActiveState Perl|http://www.activestate.com/activeperl>
doesn't have all of the necessary modules available.

B<WARNING>

    Not all of the Perl modules have been included to make the software 
    run. You may need to load additional CPAN modules. How you do this,
    is dependent on how you manage your systems. This software requires 
    Perl 5.8.8 or higher to operate.

=head1 POST INSTALLATION

On Unix like systems, this installation also creates a "xas" user and group.
This is used to set permissions on files and for user context when running 
daemons. A xas.sh file is placed in the /etc/profile.d directory to define 
environment variables for the XAS system. 

On Windows, a xas.bat file is placed in %XAS_ROOT%/etc/profile.d. This defines
the environment variables for the XAS system. They are not set at the system
level. You may wish to do so.

The following environment variables are available to adjust the system. These
reflect a Unix like system. Equivalent variables are available on Windows.

    XAS_HOSTNAME="localhost"
    XAS_DOMAIN="example.com"

    XAS_MXPORT="25"
    XAS_MXSERVER="localhost"
    XAS_MXMAILER='sendmail'

    XAS_MQPORT="61613"
    XAS_MQSERVER="localhost"
    XAS_MQLEVEL="1.0"

    XAS_MSGS=".*\.msg$"
    XAS_LOG_TYPE="console"
    XAS_LOG_FACILITY="local6"

    XAS_ERR_THROWS="xas"
    XAS_ERR_PRIORITY="low"
    XAS_ERR_FACILITY="systems"

    XAS_ROOT="/"
    XAS_SBIN="/usr/sbin"
    XAS_BIN="/usr/bin"
    XAS_ETC="/etc/xas"
    XAS_VAR="/var'
    XAS_LIB="/var/lib/xas"
    XAS_LOG="/var/log/xas"
    XAS_LOCKS="/var/lock/xas"
    XAS_RUN="/var/run/xas"
    XAS_SPOOL="/var/spool/xas"
      
In either environment, if your network name resolution is slow, you
may want to define the XAS_HOSTNAME and XAS_DOMAIN environment variables. 
This will speed start up times considerably. 

This software requires a STOMP compatible message queue server. If it is
not running on the local host, then you will need to define the XAS_MQSERVER
environment variable to point to it. If it is not listening on the
default port, then you need to define the XAS_MQPORT environment
variable. The default STOMP protocol level is v1.0. If you want to change
this, you need to set the XAS_MQLEVEL environment variable. The XAS
system supports v1.0, v1.1 and v1.2. This system has been tested with 
L<RabbitMQ|http://http://www.rabbitmq.com/> and 
L<POE::Component::MessageQueue|https://metacpan.org/pod/POE::Component::MessageQueue>.

This software also requires a SMTP based mail server. How mail is sent is 
defined by the XAS_MXMAILER environment variable.

On Unix like systems, this is "sendmail". Your system will need a "sendmail"
compatible command. Which most Unix mail systems provide.

On Windows this is "smtp". If the mail server is not running on the local 
host, then you will need to define the XAS_MXSERVER environment variable to 
point to it. If it is not listening on the default port, then you need to 
define the XAS_MXPORT environment variable. This setup works quite nicely 
with MS Exchange.

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc XAS

Extended documentation is available here:

    http://scm.kesteb.us/trac

The latest and greatest is always available at:

    http://scm.kesteb.us/git/XAS

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
