use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'YAML::LoadFileCached',
    'VERSION_FROM'	=> 'lib/YAML/LoadFileCached.pm', # finds $VERSION
    'PREREQ_PM'		=> {YAML => 0.30}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/YAML/LoadFileCached.pm', # retrieve abstract from module
       AUTHOR     => 'Florian Helmberger <fh@laudatio.com>') : ()),
);
