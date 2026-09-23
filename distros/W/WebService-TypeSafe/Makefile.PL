use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::TypeSafe',
    VERSION_FROM     => 'lib/WebService/TypeSafe.pm',
    ABSTRACT_FROM    => 'lib/WebService/TypeSafe.pm',
    AUTHOR           => 'Data Sculpting Inc. <info@datasculpting.com>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.020',
    PREREQ_PM        => {
        'Carp'       => 0,
        'HTTP::Tiny' => 0,
        'JSON::PP'   => 0,
        'Scalar::Util' => 0,
        'Time::HiRes'  => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        resources => {
            homepage => 'https://datasculpting.com/',
        },
        'x_provided_by' => 'Data Sculpting Inc.',
    },
);
