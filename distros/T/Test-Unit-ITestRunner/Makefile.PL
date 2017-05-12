use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Unit::ITestRunner',
    VERSION_FROM      => 'lib/Test/Unit/ITestRunner.pm', # finds $VERSION
    PREREQ_PM         => {'Test::Unit' => '0.1', 'Time::HiRes' => '1.9'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Unit/ITestRunner.pm', # retrieve abstract from module
       AUTHOR         => 'cmapuk[0nline] <cmapuk.0nline@gmail.com>') : ()),
);
