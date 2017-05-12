package XAS::Docs::Service::Installation;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Service::Installation - how to install the XAS Service environment

XAS is operations middleware for Perl. It provides standardized methods, 
modules and philosophy for constructing large distributed applications. This 
system is based on production level code.

=head1 GETTING THE CODE

Since the code repository is git based, you can use the following commands:

    # mkdir XAS-Service
    # cd XAS-Service
    # git init
    # git pull http://scm.kesteb.us/git/XAS-Service master

Or you can download the code from CPAN in the following manner:

    # cpan -g XAS-Service
    # tar -xvf XAS-Service-0.01.tar.gz
    # cd XAS-0.01

It is suggested that you do not do an automated cpan based install, as it 
will not set up the environment correctly. In either case the following 
commands are run from that directory.

=head1 INSTALLATION

On Unix like systems, using pure Perl, run the following commands:

    # perl Build.PL --installdirs site
    # ./Build
    # ./Build test
    # ./Build install

If you are DEB based, Debian build files have been provided. If you have a 
Debian build environment, then you can do the following:

    # debian/rules build
    # debian/rules clean
    # dpkg -i ../libxas-service-perl_0.01-1_all.deb

If you are RPM based, a spec file has been included. If you have a
rpm build environment, then you can do the following:

    # perl Build.PL
    # ./Build
    # ./Build test
    # ./Build dist
    # rpmbuild -ta XAS-Service-0.01.tar.gz
    # cd ~/rpmbuild/RPMS/noarch
    # yum --nogpgcheck localinstall perl-XAS-Service-0.01-1.noarch.rpm

Each of these installation methods will overlay the local file system and
tries to follow Debian standards for file layout and package installation. 

On Windows, do the following:

    > perl Build.PL
    > Build
    > Build test
    > Build install

It is recommended that you useL<Strawberry Perl|http://strawberryperl.com/>, 
L<ActiveState Perl|http://www.activestate.com/activeperl>
doesn't have all of the necessary modules available.

B<WARNING>

    Not all of the Perl modules have been included to make the software 
    run. You may need to load additional CPAN modules. How you do this,
    is dependent on how you manage your systems. This software requires 
    Perl 5.8.8 or higher to operate.

=head1 POST INSTALLATION

This package includes a test micro server. You may want to check the 
configuration file to see if it reflects your environment.

Once that is done. You need to start the collector. On Debian or RHEL
you would issue the following commands:

    # service xas-testd start
    # chkconfig --add xas-testd

On Windows, use these commands:

   > xas-testd --install
   > sc start XAS_TESTD

Now you can check the log files for any errors and proceed from there.


=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc XAS-Service

Extended documentation is available here:

    http://scm.kesteb.us/trac

The latest and greatest is always available at:

    http://scm.kesteb.us/git/XAS-Service

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
