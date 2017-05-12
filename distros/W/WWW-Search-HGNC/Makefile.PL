use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Search::HGNC',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Search/HGNC.pm',
    ABSTRACT_FROM       => 'lib/WWW/Search/HGNC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'WWW::Search' => 0,
        'WWW::SearchResult' => 0,
        'Text::RecordParser::Tab' => 0,
        'Text::ParseWords' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Search-HGNC-*' },
);
