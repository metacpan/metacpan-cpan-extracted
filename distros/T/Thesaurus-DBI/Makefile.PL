use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Thesaurus::DBI',
    VERSION_FROM      => 'lib/Thesaurus/DBI.pm', # finds $VERSION
    PREREQ_PM         => {'DBI'=>1, 'Thesaurus' => 0.21},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Thesaurus/DBI.pm', # retrieve abstract from module
       AUTHOR         => 'Jo Seibert jseibert (at) seibert-media (dot) net') : ()),
);
