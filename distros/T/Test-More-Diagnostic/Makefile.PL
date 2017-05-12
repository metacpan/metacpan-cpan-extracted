use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Test::More::Diagnostic',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Test/More/Diagnostic.pm',
    ABSTRACT_FROM => 'lib/Test/More/Diagnostic.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'                   => 0,
        'TAP::Parser::YAMLish::Writer' => 2.99
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Test-More-Diagnostic-*' },
);
