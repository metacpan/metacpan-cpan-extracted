#!/usr/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     NAME      => 'Tie::Hash::RegexKeys',
     VERSION_FROM => 'RegexKeys.pm', # finds $VERSION
     ABSTRACT       => 'Extend Tie::Hash::Regex to retrieve the KEYS in place of values',
             dist => { COMPRESS=>"gzip -f", SUFFIX=>"gz" },
     PREREQ_PM => {  'Tie::Hash::Regex' },
     PREREQ_FATAL => 1,

);
