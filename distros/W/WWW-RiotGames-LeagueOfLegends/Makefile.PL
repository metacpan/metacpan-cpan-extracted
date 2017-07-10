use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'WWW::RiotGames::LeagueOfLegends',
  AUTHOR => 'Justin Hunter <justin.d.hunter@gmail.com>',
  ABSTRACT_FROM => 'lib/WWW/RiotGames/LeagueOfLegends.pm',
  VERSION_FROM => 'lib/WWW/RiotGames/LeagueOfLegends.pm',
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.14.0',
  PREREQ_PM => {
    JSON              => 0,
    LWP               => 0,
    Moo               => 0,
    URI               => 0,
    'Sub::Name'       => 0,
    'Types::Standard' => 0,
    'Function::Parameters' => 0,
  },
  BUILD_REQUIRES => {
    'Test::More' => '0.88',
  },
  META_MERGE => {
    resources => {
      license     => 'http://dev.perl.org/licenses/',
      bugtracker  => 'https://github.com/arcanez/www-riotgames-leagueoflegends/issues',
      repository  => 'https://github.com/arcanez/www-riotgames-leagueoflegends',
    },
  },
);
