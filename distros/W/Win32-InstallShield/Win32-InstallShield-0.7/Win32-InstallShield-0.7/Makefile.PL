use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Win32::InstallShield',
    'VERSION_FROM'      => 'lib/Win32/InstallShield.pm', # finds $VERSION
    'PREREQ_PM'         => {XML::Parser => 2.34}, # e.g., Module::Name => 1.1
    'LICENSE'		=> 'perl',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Win32/InstallShield.pm', # retrieve abstract from module
       AUTHOR     => 'Kirk Baucom <kbaucom@schizoid.com>') : ()),
);

