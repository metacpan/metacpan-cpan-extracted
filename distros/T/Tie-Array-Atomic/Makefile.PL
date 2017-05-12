use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::Array::Atomic',
    VERSION_FROM      => 'lib/Tie/Array/Atomic.pm', # finds $VERSION
    PREREQ_PM         => { Devel::Malloc => 0.03, Tie::Array }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'lib/Tie/Array/Atomic.pm', # retrieve abstract from module
       AUTHOR         => 'Yury Kotlyarov') : ()),
);
