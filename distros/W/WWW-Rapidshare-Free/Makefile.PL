use 5.006000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Rapidshare::Free',
    AUTHOR        => 'Alan Haggai Alavi <alanhaggai@alanhaggai.org>',
    VERSION_FROM  => 'lib/WWW/Rapidshare/Free.pm',
    ABSTRACT_FROM => 'lib/WWW/Rapidshare/Free.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'WWW::Mechanize'      => 0,
        'HTML::Form'          => 0,
        'HTML::Parser'        => 0,
        'Data::Validate::URI' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'WWW-Rapidshare-Free-*' },
);
