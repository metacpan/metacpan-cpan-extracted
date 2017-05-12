use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::Autotie',
    VERSION_FROM      => 'lib/Tie/Autotie.pm', # finds $VERSION
    PREREQ_PM         => { 'Tie::IxHash' => 1.21 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/Autotie.pm', # retrieve abstract from module
       AUTHOR         => 'japhy <japhy@>') : ()),
);
