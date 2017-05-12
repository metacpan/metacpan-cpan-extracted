use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ebXML',
    VERSION_FROM      => 'lib/ebXML.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ebXML.pm', # retrieve abstract from module
       AUTHOR         => 'Aaron Trevena <aaron.trevena@surreytech.co.uk>') : ()),
);
