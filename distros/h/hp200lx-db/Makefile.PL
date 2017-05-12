#!/usr/local/bin/perl
# FILE .../CPAN/hp200lx-db/Makefile.PL
#
# written:       1998-06-16
# latest update: 1998-09-27 21:22:52
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'HP200LX::DB',
    'VERSION_FROM' => 'DB.pm',          # finds $VERSION
    'PMLIBDIRS'    => [ 'DB', 'DBgui' ],
);
