use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::CheckVariables',
    VERSION_FROM      => 'lib/Tie/CheckVariables.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/CheckVariables.pm', # retrieve abstract from module
       AUTHOR         => 'Renee Baecker <module@renee-baecker.de>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE        => 'perl') : ()),
);
