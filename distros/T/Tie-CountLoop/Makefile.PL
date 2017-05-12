#!/usr/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     NAME      => 'Tie::CountLoop',
     VERSION_FROM => 'lib/Tie/CountLoop.pm', # finds $VERSION
     ABSTRACT       => 'Tie::CountLoop Is a tie SCALAR with automatic increment/decrement untill a extramum value (with reset)',
     dist => { COMPRESS=>"gzip -f", SUFFIX=>"gz" }, 
     PREREQ_PM => {  },
     PREREQ_FATAL => 1,
);
