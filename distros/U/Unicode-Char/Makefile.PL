#
# $Id: Makefile.PL,v 0.02 2022/03/19 04:27:27 dankogai Exp $
#
use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Unicode::Char',
    VERSION_FROM      => 'lib/Unicode/Char.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Unicode/Char.pm', # retrieve abstract from module
       AUTHOR         => 'Dan Kogai <dankogai@dan.co.jp>') : ()),
);
