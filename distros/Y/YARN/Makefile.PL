use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'YARN',
    AUTHOR           => q{Ahmed Ossama <ahmed@aossama.com>},
    VERSION_FROM     => 'lib/YARN.pm',
    ABSTRACT_FROM    => 'lib/YARN.pm',
    LICENSE          => 'apache_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'REST::Client'	=> 0,
        'JSON'			=> 2.90,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'YARN-*' },
);
