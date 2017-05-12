use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'constant::override',
    AUTHOR         => q{Tom Harrison <cpan@apnic.net>},
    LICENSE        => 'perl',
    VERSION_FROM   => 'lib/constant/override.pm',
    ABSTRACT_FROM  => 'lib/constant/override.pm',
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/APNIC-net/p5-constant-override'
        }
    },
    PL_FILES       => {},
    PREREQ_PM      => {
        'Sub::Uplevel' => '0',
        'Test::Pod'    => '0.95',
        'Test::More'   => '0.90',
    },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
);
