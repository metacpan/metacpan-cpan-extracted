use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::Scalar::Timestamp',
    VERSION_FROM      => 'lib/Tie/Scalar/Timestamp.pm', # finds $VERSION
    PREREQ_PM         => {
        POSIX => 1.08,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/Scalar/Timestamp.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Eichman <peichman@cpan.org>') : ()),
);
