use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::More::Color',
    AUTHOR              => q{coolmen <coolmen78@google.com>},
    VERSION_FROM        => 'lib/Test/More/Color.pm',
    ABSTRACT_FROM       => 'lib/Test/More/Color.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-More-Color-*' },
);
