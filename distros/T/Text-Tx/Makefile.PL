#
# $Id: Makefile.PL,v 0.2 2009/02/21 14:44:54 dankogai Exp dankogai $
#
use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

our $CC = 'g++';
WriteMakefile(
    NAME         => 'Text::Tx',
    VERSION_FROM => 'lib/Text/Tx.pm',    # finds $VERSION
    PREREQ_PM    => {},                  # e.g., Module::Name => 1.1
    CC           => $CC,
    LD           => '$(CC)',
    LIBS         => '-ltx',
    #INC          => '-I/usr/local/include/tx',
    XSOPT        => '-C++',
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Text/Tx.pm',    # retrieve abstract from module
            AUTHOR => 'Dan <dankogai@dan.co.jp>'
          )
        : ()
    ),
);
