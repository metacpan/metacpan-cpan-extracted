use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Time::Random',
    AUTHOR           => q{lnation <email@lnation.org>},
    VERSION_FROM     => 'lib/Time/Random.pm',
    ABSTRACT_FROM    => 'lib/Time/Random.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'Time::Piece' => '0',
	},
    PREREQ_PM => {
        'Time::Piece'	=> '0',
        'Import::Export' => '1.00',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Random-*' },
);
