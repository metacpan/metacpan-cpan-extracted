use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Mimic::Recorder',
    VERSION_FROM      => 'lib/Test/Mimic/Recorder.pm', # finds $VERSION
    PREREQ_PM         => {
        'Devel::EvalError' => 0,
        'Cwd' => 0,
        'Scalar::Util' => 0,
        'Test::Mimic::Library' => 0,
        'Test::More' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Mimic/Recorder.pm', # retrieve abstract from module
       AUTHOR         => 'Brendan Roof <broof@>') : ()),
);
