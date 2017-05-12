use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Search::PubMedLite',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/WWW/Search/PubMedLite.pm',
    ABSTRACT_FROM       => 'lib/WWW/Search/PubMedLite.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'WWW::Search'    => 0,
        'HTML::Entities' => 0,
        'XML::LibXML'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Search-PubMedLite-*' },
);
