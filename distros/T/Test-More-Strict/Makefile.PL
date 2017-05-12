use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME    => 'Test::More::Strict',
    AUTHOR  => 'Andy Armstrong <andy.armstrong@messagesystems.com>',
    LICENSE => 'perl',
    VERSION_FROM  => 'lib/Test/More/Strict.pm',
    ABSTRACT_FROM => 'lib/Test/More/Strict.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'   => 0,
        'TAP::Harness' => '3.11',
        'TAP::Parser'  => '3.11',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Test-More-Strict-*' },
);
