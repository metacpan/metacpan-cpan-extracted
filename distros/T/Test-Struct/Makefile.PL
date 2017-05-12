use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Struct',
    VERSION_FROM      => 'lib/Test/Struct.pm', # finds $VERSION
    PREREQ_PM         => {
            Test::Builder         => 0,
            Scalar::Util          => 0,
            Test::Builder::Tester => 0,
        },
    ($] >= 5.005
    ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Struct.pm', # retrieve abstract from module
       AUTHOR         => 'Yves Orton')
    : (ABSTRACT=>'Perl extension for testing for structural equivelence.')
    ),
);
