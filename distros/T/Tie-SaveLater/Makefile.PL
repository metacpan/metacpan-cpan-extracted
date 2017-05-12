#
# $Id: Makefile.PL,v 0.3 2006/03/22 22:10:28 dankogai Exp $
#
use 5.008; # recent enough?
use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::SaveLater',
    VERSION_FROM      => 'lib/Tie/SaveLater.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/SaveLater.pm', 
       AUTHOR         => 'Dan Kogai <dankogai@@dan.co.jp>') : ()),
);
