use v5.6.1;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Litmus',
    VERSION_FROM      => 'lib/Test/Litmus.pm', # finds $VERSION
    PREREQ_PM         => {'LWP::UserAgent' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Litmus.pm', # retrieve abstract from module
       AUTHOR         => 'Zach Lipton <zach@zachlipton.com>') : ()),
);
