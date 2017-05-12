#!/usr/bin/perl
use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::EntrySet',
    VERSION_FROM      => 'lib/Tk/EntrySet.pm', # finds $VERSION
    PREREQ_PM         => {Tk           => '804.027',
                          },

   ($ExtUtils::MakeMaker::VERSION >= 6.301 ?
       (LICENSE      => "perl") : (),
   ),
    ABSTRACT_FROM  => 'lib/Tk/EntrySet.pm', # retrieve abstract from module
    AUTHOR         => 'Ch.Lamprecht <ch.l.ngre@online.de>',
          );
