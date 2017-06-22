use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Expr',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Test/Expr.pm',
    ABSTRACT_FROM       => 'lib/Test/Expr.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.010,
    PREREQ_PM => {
        'Test::More'       => 0,
        'Keyword::Declare' => '0.001',
        'Data::Dump'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Expr-*' },
);
