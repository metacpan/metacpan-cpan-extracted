

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'mem',
    VERSION_FROM => 'lib/mem.pm', # finds \$VERSION
    AUTHOR       => 'Linda Walsh (LAWALSH@cpan.org)',
    ABSTRACT     => "allow use of packages already in 'mem'ory",
    BUILD_REQUIRES=> { 'ExtUtils::MakeMaker' => 6.82, },
    TEST_REQUIRES=> {
                     'Test::Simple' => 0.44,
                   },
    dist        => { TAR=> 'ptar', TARFLAGS=> "-cvf" },
);
