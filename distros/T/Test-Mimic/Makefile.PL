use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Mimic',
    VERSION_FROM      => 'lib/Test/Mimic.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::Mimic::Library' => 0,
        'Test::Mimic::Generator' => 0,
        'Test::Mimic::Recorder' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Mimic.pm', # retrieve abstract from module
       AUTHOR         => 'Brendan Roof') : ()),
);
