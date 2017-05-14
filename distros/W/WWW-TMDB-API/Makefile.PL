use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::TMDB::API',
    AUTHOR        => q{Maria Celina Baratang <maria@zambale.com>},
    VERSION_FROM  => 'lib/WWW/TMDB/API.pm',
    ABSTRACT_FROM => 'lib/WWW/TMDB/API.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Request'  => 0,
        'JSON'           => 0,
        'URI'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'WWW-TMDB-API-*' },
);
