use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Scrape::Mailman::RSS',
    AUTHOR              => q{Hugh Esco <hesco@campaignfoundations.com>},
    VERSION_FROM        => 'lib/WWW/Scrape/Mailman/RSS.pm',
    ABSTRACT_FROM       => 'lib/WWW/Scrape/Mailman/RSS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More' => 0,
              'WWW::Mechanize' => 0,
          'HTML::TableExtract' => 0,
                   'XML::Twig' => 0,
                    'XML::RSS' => 0,
    'HTML::TokeParser::Simple' => 0,
                'Data::Dumper' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Scrape-Mailman-RSS-*' },
);
