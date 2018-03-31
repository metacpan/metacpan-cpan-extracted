use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::DocClaims',
    VERSION_FROM      => 'lib/Test/DocClaims.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More' => 0.80,
    },
    LICENSE           => "perl",
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/DocClaims.pm', # retrieve abstract from module
       AUTHOR         => 'Scott E. Lee <ScottLee@cpan.org>') : ()),
);
