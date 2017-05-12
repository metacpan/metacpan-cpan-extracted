use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Test::Steering',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Test/Steering.pm',
    ABSTRACT_FROM => 'lib/Test/Steering.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Carp'              => 0,
        'Exporter'          => 0,
        'File::Spec'        => 0,
        'IO::CaptureOutput' => '1.05',
        'Scalar::Util'      => 0,
        'TAP::Harness'      => '3.04',
        'Test::More'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Test-Steering-*' },
);
