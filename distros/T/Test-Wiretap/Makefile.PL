use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Wiretap',
    AUTHOR              => 'Airwave Wireless <cpan@airwave.com>',
    VERSION_FROM        => 'lib/Test/Wiretap.pm',
    ABSTRACT_FROM       => 'lib/Test/Wiretap.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Resub' => '1.04',
        'Class::Delegator' => '0.01',
        'Class::Std' => 0,
        'Storable' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Wiretap-*' },
);
