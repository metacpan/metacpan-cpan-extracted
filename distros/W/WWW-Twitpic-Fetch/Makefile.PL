use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Twitpic::Fetch',
    AUTHOR              => 'turugina <turugina@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Twitpic/Fetch.pm',
    ABSTRACT_FROM       => 'lib/WWW/Twitpic/Fetch.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose' => 0,
        'LWP::UserAgent' => 0,
        'Web::Scraper' => 0,
        'URI' => 0,
        'Carp' => 0,
        'List::MoreUtils' => 0,
        'Text::Trim' => 0,
        'Encode' => 0,
        'IO::File' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Twitpic-Fetch-*' },
);
