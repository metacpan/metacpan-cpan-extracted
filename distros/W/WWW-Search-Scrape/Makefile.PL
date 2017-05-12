use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Search::Scrape',
    AUTHOR              => q{Quan Sun <qsun@pardiff.com>},
    VERSION_FROM        => 'lib/WWW/Search/Scrape.pm',
    ABSTRACT_FROM       => 'lib/WWW/Search/Scrape.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More' => 0,
                  'WWW::Mechanize' => 0,
                  'HTML::TreeBuilder' => 0,
                  'Data::Dumper' => 0, 
                  'Test::Simple' => 0,
		  'HTML::TreeBuilder::XPath' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Search-Scrape-*' },
);
