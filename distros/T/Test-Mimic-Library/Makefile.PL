use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Mimic::Library',
    VERSION_FROM      => 'lib/Test/Mimic/Library.pm', # finds $VERSION
    PREREQ_PM         => {
        'Data::Dumper' => 0,
        'Scalar::Util' => 0,
        'Tie::Array' => 0,
        'Tie::Hash' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Mimic/Library.pm', # retrieve abstract from module
       AUTHOR         => 'Brendan Roof <broof@>') : ()),
);
