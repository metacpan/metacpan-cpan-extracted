use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Search::DrugBank',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Search/DrugBank.pm',
    ABSTRACT_FROM       => 'lib/WWW/Search/DrugBank.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'WWW::Search' => 0,
        'XML::LibXML' => 0,
        'HTML::TreeBuilder' => 0,
        'HTML::Entities' => 0,
        'URI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Search-DrugBank-*' },
);
