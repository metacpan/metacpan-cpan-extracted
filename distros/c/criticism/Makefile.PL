#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/Makefile.PL $
#     $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 206 $
########################################################################

use 5.006001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME           => 'criticism',
    AUTHOR         => 'Jeffrey Thalhammer <thaljef@cpan.org>',
    ABSTRACT_FROM  => 'lib/criticism.pm',
    VERSION_FROM   => 'lib/criticism.pm',
    PREREQ_PM      => {
        'Perl::Critic' => 1.089,
        'Test::More'   => 0,
        'IO::String'   => 0,
    },
    PL_FILES       => {},
);
