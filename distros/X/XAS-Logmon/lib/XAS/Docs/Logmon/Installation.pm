package XAS::Docs::Logmon::Installation;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Logmon::Installation - how to install the XAS Log Monitor

XAS is middleware for datacenter operations. It provides standardized methods, 
modules and philosophy for constructing applications typically used to manage
a datacenter. This system is based on production level code.

=head1 GETTING THE CODE

Since the code repository is git based, you can use the following commands:

    # mkdir XAS-Logmon
    # cd XAS-Logmon
    # git init
    # git pull http://scm.kesteb.us/git/XAS-Logmon master

Or you can download the code from CPAN in the following manner:

    # cpan -g XAS-Logmon
    # tar -xvf XAS-Logmon-0.01.tar.gz
    # cd XAS-Logmon-0.01

When done, the following commands are run from that directory.

=head1 INSTALLATION

On Unix like systems, using pure Perl, run the following commands:

    # perl Build.PL --installdirs vendor
    # ./Build
    # ./Build test
    # ./Build install
    # ./Build debian    # removes redhat specific files when installing on debian
    # ./Build redhat    # removes debian specific files when installing on redhat

If you are DEB based, Debian build files have been provided. If you have a 
Debian build environment, then you can do the following:

    # debian/rules build
    # debian/rules clean
    # dpkg -i ../libxas-logmon-perl_0.01-1_all.deb

If you are RPM based, a spec file has been included. If you have a
rpm build environment, then you can do the following:

    # perl Build.PL
    # ./Build --installdirs vendor
    # ./Build test
    # ./Build dist
    # rpmbuild -ta XAS-Logmon-0.01.tar.gz
    # cd ~/rpmbuild/RPMS/noarch
    # yum --nogpgcheck localinstall perl-XAS-Logmon-0.01-1.noarch.rpm

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

When installing on Linux you may have to increase these kernel values:

 fs.inotify.max_user_watches
 fs.inotify.max_user_instances

You should also check the log monitors configuration file to see if the proper
files are being monitored. By default, it only monitors $XAS_LOG/xas-collector.log
and $XAS_LOG/xas-spooler.log.

Once that is done. You need to start the log monitor. On Debian or RHEL
you would issue the following commands:

    # service xas-logmon start
    # chkconfig --add xas-logmon

On Windows, use these commands:

   > xas-logmon --install
   > sc start XAS_LOGMON

Now you can check the log files for any errors and proceed from there.

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc XAS-Logmon

Extended documentation is available here:

    http://scm.kesteb.us/trac

The latest and greatest is always available at:

    http://scm.kesteb.us/git/XAS-Logmon

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
