use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Maker',
    'VERSION_FROM'	=> 'Maker.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Maker.pm', # retrieve abstract from module
       AUTHOR     => 'Vadim Trochinsky <perl-mods@vadim.ws>') : ()),
);
