#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Test-Perl-Critic-Progressive-0.03/Makefile.PL $
#     $Date: 2008-07-27 16:01:56 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 2620 $
########################################################################

use 5.006001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Test::Perl::Critic::Progressive',
    AUTHOR         => 'Jeffrey Thalhammer <thaljef@cpan.org>',
    ABSTRACT_FROM  => 'lib/Test/Perl/Critic/Progressive.pm',
    VERSION_FROM   => 'lib/Test/Perl/Critic/Progressive.pm',
    PL_FILES       => {},
    PREREQ_PM      => {
        'base'                      => 0,
        'Carp'                      => 0,
        'Data::Dumper'              => 0,
        'English'                   => 0,
        'Exporter'                  => 0,
        'File::Spec'                => 0,
        'FindBin'                   => 0,
        'Perl::Critic'              => 1.082,
        'Perl::Critic::Utils'       => 1.082,
        'strict'                    => 0,
        'Test::Builder'             => 0,
        'warnings'                  => 0,

        'Test::More'                => 0,
    },
);
