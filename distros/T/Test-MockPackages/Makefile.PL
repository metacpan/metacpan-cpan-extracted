use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::MockPackages',
    AUTHOR        => q{Tom Peters <tpeters@synacor.com>},
    VERSION_FROM  => 'lib/Test/MockPackages.pm',
    ABSTRACT_FROM => 'lib/Test/MockPackages.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Const::Fast'         => 0,
        'Lingua::EN::Inflect' => 0,
        'Sub::Metadata'       => 0,
        'Test::Deep'          => 0,
        'Test::Exception'     => 0,
        'Test::More'          => 0,
        'Test::Pod'           => '1.22',
        'Test::Pod::Coverage' => '1.08',
        'Test::Tester'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Test-MockPackages-*' },
);
