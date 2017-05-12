use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::YahooJapan::WebMA',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/WebService/YahooJapan/WebMA.pm',
    (
        $ExtUtils::MakeMaker::VERSION >= 6.31
        ? (LICENSE => 'perl', ABSTRACT_FROM => 'lib/WebService/YahooJapan/WebMA.pm')
        : ()
    ),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0.32,
        'LWP'             => 5.6,
        'XML::Simple'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-YahooJapan-WebMA-*' },
);
