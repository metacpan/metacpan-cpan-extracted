use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::AD::User',
    'VERSION_FROM'	=> 'User.pm', # finds $VERSION
    'PREREQ_PM'		=> {Win32::OLE => 0.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'User.pm', # retrieve abstract from module
       AUTHOR     => 'Aaron Thompson <thompson@cns.uni.edu>') : ()),
);
