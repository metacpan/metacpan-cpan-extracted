use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Waft::JS',
    VERSION_FROM      => 'lib/Waft/JS.pm', # finds $VERSION
    PREREQ_PM         => { Waft => 0.9910 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Waft/JS.pm', # retrieve abstract from module
       AUTHOR         => 'Yuji Tamashiro <yuji@tamashiro.org>') : ()),
);
