use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Time::Precise',
    AUTHOR           => q{Francisco Zarabozo <zarabozo@cpan.org>},
    VERSION_FROM     => 'lib/Time/Precise.pm',
    ABSTRACT_FROM    => 'lib/Time/Precise.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
		'Time::HiRes'	=> 0,
    },
    PREREQ_PM => {
        'Time::HiRes'	=> 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Precise-*' },
);
