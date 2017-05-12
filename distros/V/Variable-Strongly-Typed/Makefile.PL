use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Variable::Strongly::Typed',
    AUTHOR              => 'Mark Ethan Trostler <mark@zzo.com>',
    VERSION_FROM        => 'lib/Variable/Strongly/Typed.pm',
    ABSTRACT_FROM       => 'lib/Variable/Strongly/Typed.pm',
    PREREQ_PM => {
        'Test::More'            => 0,
        'version'               => 0,
        'Class::Std::Utils'     => 0,
        'Attribute::Handlers'   => 0,
        'Tie::Hash'             => 0,
        'Tie::Array'            => 0,
        'Tie::Scalar'           => 0,
        'IO::File'              => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Variable-Strongly-Typed-*' },
);
