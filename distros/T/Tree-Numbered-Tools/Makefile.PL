use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tree::Numbered::Tools',
    VERSION_FROM      => 'lib/Tree/Numbered/Tools.pm', # finds $VERSION
    PREREQ_PM         => {'Javascript::Menu' => 2.02, 'IO::Scalar' => '0',}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tree/Numbered/Tools.pm', # retrieve abstract from module
       AUTHOR         => 'Johan Kuuse <kuuse@isc.freebsd.org>') : ()),
);
