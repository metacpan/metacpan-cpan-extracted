use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Wikipedia::TemplateFiller',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/WWW/Wikipedia/TemplateFiller.pm',
    ABSTRACT_FROM       => 'lib/WWW/Wikipedia/TemplateFiller.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Cache::SizeAwareFileCache' => 0,
        'CGI::Application' => 0,
        'Date::Calc' => 0,
        'Tie::IxHash' => 0,
        'WWW::Mechanize' => 0,
        'WWW::Scraper::ISBN' => 0,
        'WWW::Scraper::ISBN::ISBNdb_Driver' => 0,
        'WWW::Search' => 0,
        'WWW::Search::DrugBank' => 0,
        'WWW::Search::HGNC' => 0,
        'WWW::Search::PubChem' => 0,
        'WWW::Search::PubMedLite' => 0.05, # pmc_id support/error handling
        'XML::Writer' => 0,
        'Lingua::EN::Titlecase' => 0, # for 'full_journal_title' support
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Wikipedia-TemplateFiller-*' },
);
