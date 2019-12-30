use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker;
WriteMakefile
(
    NAME             => 'Validate::Simple',
    VERSION_FROM     => 'lib/Validate/Simple.pm',
    ABSTRACT_FROM    => 'lib/Validate/Simple.pm',
    AUTHOR           => 'Andrei Pratasavitski <andrei.protasovitski@gmail.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010000',
    PREREQ_PM        => {
        'Carp'         => 0,
        'Scalar::Util' => 0,
        'Data::Types'  => 0,
        'Data::Dumper' => 0,
    },
    TEST_REQUIRES    => {
        'Test::More' => 0,
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/as_pushkin/validate-simple.git',
                web  => 'https://gitlab.com/as_pushkin/validate-simple',
            },
        },
    },
);

1;
