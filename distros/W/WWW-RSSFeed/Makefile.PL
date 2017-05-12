use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::RSSFeed',
    AUTHOR              => q{Jaiswal, Kunal <nicks@cpan.org>},
    VERSION_FROM        => 'lib/WWW/RSSFeed.pm',
    ABSTRACT_FROM       => 'lib/WWW/RSSFeed.pm',
    PREREQ_PM => {
      'threads'              => 1.75,
      'threads::shared'      => 1.32,
      'WWW::Mechanize'       => 1.68,
      'Domain::PublicSuffix' => 0.04,
      'XML::RSS'             => 1.49,
      'HTML::Summary'        => 0.017,
      'HTML::TreeBuilder'    => 5.03,
      'HTML::Scrubber'       => 0.09,
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-RSSFeed-*' },
);
