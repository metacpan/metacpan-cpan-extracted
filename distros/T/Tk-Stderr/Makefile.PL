use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tk::Stderr',
    'VERSION_FROM'	=> 'Stderr.pm', # finds $VERSION
    'PREREQ_PM'		=> { Tk => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Stderr.pm', # retrieve abstract from module
       AUTHOR     => 'Kevin Michael Vail <kevin@vaildc.net>') : ()),
);
