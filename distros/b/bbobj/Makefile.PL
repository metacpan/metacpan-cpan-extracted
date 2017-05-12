## $Id: Makefile.PL,v 1.1.1.1 2002/07/14 04:13:15 dshanks Exp $
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

system("./configure.pl");

WriteMakefile(
    'NAME'		=> 'BigBrother::Object',
    'VERSION_FROM'	=> 'Object.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Object.pm', # retrieve abstract from module
       AUTHOR     => 'Don Shanks <perldev@bpss.net>') : ()),
);
