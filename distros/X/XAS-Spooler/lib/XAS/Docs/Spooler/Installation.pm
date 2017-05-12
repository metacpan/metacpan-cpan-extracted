package XAS::Docs::Spooler::Installation;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Spooler::Installation - how to install the XAS Spooler

XAS is middleware for datacenter operations. It provides standardized methods, 
modules and philosophy for constructing applications typically used to manage
a datacenter. This system is based on production level code.

=head1 GETTING THE CODE

Since the code repository is git based, you can use the following commands:

    # mkdir XAS-Spooler
    # cd XAS-Spooler
    # git init
    # git pull http://scm.kesteb.us/git/XAS-Spooler master

Or you can download the code from CPAN in the following manner:

    # cpan -g XAS-Spooler
    # tar -xvf XAS-Spooler-0.01.tar.gz
    # cd XAS-Spooler-0.01

When done, the following commands are run from that directory.

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
    # dpkg -i ../libxas-spooler-perl_0.01-1_all.deb

If you are RPM based, a spec file has been included. If you have a
rpm build environment, then you can do the following:

    # perl Build.PL
    # ./Build --installdirs vendor
    # ./Build test
    # ./Build dist
    # rpmbuild -ta XAS-Spooler-0.01.tar.gz
    # cd ~/rpmbuild/RPMS/noarch
    # yum --nogpgcheck localinstall perl-XAS-Spooler-0.01-1.noarch.rpm

Each of these installation methods will overlay the local file system and
tries to follow Debian standards for file layout and package installation. 

On Windows, do the following:

    > perl Build.PL
    > Build
    > Build test
    > Build install

It is recommended that you use L<Strawberry Perl|http://strawberryperl.com/>, 
L<ActiveState Perl|http://www.activestate.com/activeperl>
doesn't have all of the necessary modules available. 

B<WARNING>

    Not all of the Perl modules have been included to make the software 
    run. You may need to load additional CPAN modules. How you do this,
    is dependent on how you manage your systems. This software requires 
    Perl 5.8.8 or higher to operate.

=head1 POST INSTALLATION

You should check the spoolers configuration file to see if the proper
directories are being monitored. By default, it only monitors $XAS_SPOOL/alerts
and $XAS_SPOOL/logs.

Once that is done. You need to start the spooler. On Debian or RHEL
you would issue the following commands:

    # service xas-spooler start
    # chkconfig --add xas-spooler

On Windows, use these commands:

   > xas-spooler --install
   > sc start XAS_SPOOLER

Now you can check the log files for any errors and proceed from there.

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc XAS-Spooler

Extended documentation is available here:

    http://scm.kesteb.us/trac

The latest and greatest is always available at:

    http://scm.kesteb.us/git/XAS-Spooler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
