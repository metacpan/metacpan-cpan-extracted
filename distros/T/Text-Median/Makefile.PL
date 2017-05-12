use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Median',
    VERSION_FROM      => 'lib/Text/Median.pm', # finds $VERSION
    PREREQ_PM         => { Module::Runtime => 0.006, Test::Warn => 0.11 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Median.pm', # retrieve abstract from module
       AUTHOR         => 'Leigh  Metcalf <leigh@local>') : ()),
);
