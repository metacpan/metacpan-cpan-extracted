use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Upp::Reader',
    VERSION_FROM      => 'lib/Upp/Reader.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  =>   'Upp reader', # retrieve abstract from module
       AUTHOR         => 'Marton Papp <equinox@atw.hu>') : ()),
);
