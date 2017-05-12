#
# $Id: Makefile.PL,v 0.3 2011/01/11 04:45:59 dankogai Exp dankogai $
#
use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $CC = 'g++';
WriteMakefile(
    NAME         => 'Text::Darts',
    VERSION_FROM => 'lib/Text/Darts.pm',    # finds $VERSION
    PREREQ_PM    => {},                     # e.g., Module::Name => 1.1
    CC           => $CC,
    LD           => '$(CC)',
    XSOPT        => '-C++',
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Text/Darts.pm',    # retrieve abstract from module
            AUTHOR => 'Dan <dankogai@dan.co.jp>'
          )
        : ()
    ),
);
