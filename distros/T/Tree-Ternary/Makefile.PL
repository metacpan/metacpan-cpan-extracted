#!/usr/local/bin/perl
###########################################################################
# $Id: Makefile.PL,v 1.1 2003/09/27 21:28:46 wendigo Exp $
###########################################################################
#
# Author: Mark Rogaski <wendigo@pobox.com>
# RCS Revision: $Revision: 1.1 $
# Date: $Date: 2003/09/27 21:28:46 $
#
###########################################################################
#
# See README for license information.
#
###########################################################################
use ExtUtils::MakeMaker;

sub get_version {
    my($pkg) = @_;
    eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };
    ${"${pkg}::VERSION"}
}

#
# Check prerequisites
#
unless (my $ver = get_version('Test')) {
    warn qq[
*** Test.pm not found on this system.  For 'make test' to work,
    you should have version 1.14 or greater of Test.pm from 
    CPAN/modules/by-module/Test/Test-x.x.tar.gz

    If you choose not to install Test.pm, the installation will
    not be interrupted, but you will not be able to test the
    module before 'make install'.

];
} elsif ($ver < 1.14) {
    warn qq[
*** Old version (v$ver) of Test.pm found on this system.  For
    'make test' to work, you should have version 1.14 or greater
    of Test.pm from CPAN/modules/by-module/Test/Test-x.x.tar.gz

    If you opt not to upgrade Test.pm, you will probably get several
    uninitialized variable warnings during 'make test'.  This is
    a known bug in pre-1.14 Test.pm.  As long as the tests pass,
    you should be fine.

];
}

#
# Write out the Makefile
#
WriteMakefile(
    'NAME'	=> 'Tree::Ternary',
    'VERSION_FROM' => 'Ternary.pm',
    'PREREQ_PM' => { Test => 0 }
);


