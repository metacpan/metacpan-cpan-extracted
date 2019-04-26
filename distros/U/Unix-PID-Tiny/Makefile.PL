use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Unix::PID::Tiny',
    AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM   => 'lib/Unix/PID/Tiny.pm',
    ABSTRACT_FROM  => 'lib/Unix/PID/Tiny.pm',
    PL_FILES       => {},
    PREREQ_PM      => {},
    BUILD_REQUIRES => { 'ExtUtils::MakeMaker' => 0 },
    TEST_REQUIRES  => {
        'Test::More'       => 0,
        'Test::MockFile'   => 0,
        'Test::NoWarnings' => 0,
        'Test::Warn'       => 0,
        'File::Slurp'      => 0,
        'File::Temp'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Unix-PID-Tiny-*' },
);
