#
# $Id: Makefile.PL,v 1.1.1.1 2002/10/16 10:08:08 ctriv Exp $
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::LogFile',
    'VERSION_FROM'	=> 'LogFile.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'PREREQ_PM'		=> { Test::More => 0 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'LogFile.pm', # retrieve abstract from module
       AUTHOR     => 'Chris Reinhardt <ctriv@dyndns.org>') : ()),
);
