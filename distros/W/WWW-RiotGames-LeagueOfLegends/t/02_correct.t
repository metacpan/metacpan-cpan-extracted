use strict;
use warnings;
use Test::More;

use_ok('WWW::RiotGames::LeagueOfLegends');
my $lol = WWW::RiotGames::LeagueOfLegends->new( api_key => 'testing', _testing => 1 );

# champion_mastery
{
  my $champion_mastery;
  $champion_mastery = $lol->champion_mastery( summoner_id => 1 );
  is $champion_mastery, 'https://na1.api.riotgames.com/lol/champion-mastery/v3/champion-masteries/by-summoner/1?api_key=testing', 'champion_mastery w/ summoner_id';

  $champion_mastery = $lol->champion_mastery( summoner_id => 1, champion_id => 1 );
  is $champion_mastery, 'https://na1.api.riotgames.com/lol/champion-mastery/v3/champion-masteries/by-summoner/1/by-champion/1?api_key=testing', 'champion_mastery w/ summoner_id and champion_id';

  $champion_mastery = $lol->champion_mastery( summoner_id => 1, type => 'scores' );
  is $champion_mastery, 'https://na1.api.riotgames.com/lol/champion-mastery/v3/scores/by-summoner/1?api_key=testing', 'scores w/ summoner_id';
}

# champions
{
  my $champions;
  $champions = $lol->champions();
  is $champions, 'https://na1.api.riotgames.com/lol/platform/v3/champions?api_key=testing', 'champions w/ no args'; 

  $champions = $lol->champions( champion_id => 1 );
  is $champions, 'https://na1.api.riotgames.com/lol/platform/v3/champions/1?api_key=testing', 'champions w/ champion_id'; 
}

# league
{
  my $league;
  $league = $lol->league( queue => 'foo' );
  is $league, 'https://na1.api.riotgames.com/lol/league/v3/challengerleagues/by-queue/foo?api_key=testing', 'league w/ queue foo';

  $league = $lol->league( queue => 'foo', type => 'masterleagues' );
  is $league, 'https://na1.api.riotgames.com/lol/league/v3/masterleagues/by-queue/foo?api_key=testing', 'league w/ queue foo and type masterleagues';

  $league = $lol->league( summoner_id => 1, type => 'leagues' );
  is $league, 'https://na1.api.riotgames.com/lol/league/v3/leagues/by-summoner/1?api_key=testing', 'leagues w/ summoner_id';

  $league = $lol->league( summoner_id => 1, type => 'positions' );
  is $league, 'https://na1.api.riotgames.com/lol/league/v3/positions/by-summoner/1?api_key=testing', 'positions w/ summoner_id';
}

# static_data
{
  my $static_data;

  foreach my $type (qw(champions items masteries runes summoner-spells)) {
    $static_data = $lol->static_data( type => $type );
    is $static_data, 'https://na1.api.riotgames.com/lol/static-data/v3/' . $type . '?api_key=testing', 'static_data w/ type ' . $type;

    $static_data = $lol->static_data( type => $type, id => 1 );
    is $static_data, 'https://na1.api.riotgames.com/lol/static-data/v3/' . $type . '/1?api_key=testing', 'static_data w/ type ' . $type . ' and id';
  }

  foreach my $type (qw(language-strings languages maps profile-icons realms versions)) {
    $static_data = $lol->static_data( type => $type );
    is $static_data, 'https://na1.api.riotgames.com/lol/static-data/v3/' . $type . '?api_key=testing', 'static_data w/ type ' . $type;
  }
}

# status
{
  my $status;
  $status = $lol->status();
  is $status, 'https://na1.api.riotgames.com/lol/status/v3/shard-data?api_key=testing', 'status';
}

# masteries
{
  my $masteries;
  $masteries = $lol->masteries( summoner_id => 1 );
  is $masteries, 'https://na1.api.riotgames.com/lol/platform/v3/masteries/by-summoner/1?api_key=testing', 'masteries w/ summoner_id';
}

# match
{
  my $match;
  $match = $lol->match( match_id => 1 );
  is $match, 'https://na1.api.riotgames.com/lol/match/v3/matches/1?api_key=testing', 'match w/ match_id';

  $match = $lol->match( tournament_code => 1 );
  is $match, 'https://na1.api.riotgames.com/lol/match/v3/matches/by-tournament-code/1/ids?api_key=testing', 'match w/ tournament_code';

  $match = $lol->match( match_id => 1, tournament_code => 1 );
  is $match, 'https://na1.api.riotgames.com/lol/match/v3/matches/1/by-tournament-code/1?api_key=testing', 'match w/ match_id and tournament_code';

  $match = $lol->match( account_id => 1 );
  is $match, 'https://na1.api.riotgames.com/lol/match/v3/matchlists/by-account/1?api_key=testing', 'match w/ account_id';

  $match = $lol->match( account_id => 1, recent => 1 );
  is $match, 'https://na1.api.riotgames.com/lol/match/v3/matchlists/by-account/1/recent?api_key=testing', 'match w/ account_id and recent';

  $match = $lol->match( match_id => 1, type => 'timelines' );
  is $match, 'https://na1.api.riotgames.com/lol/match/v3/timelines/by-match/1?api_key=testing', 'match w/ match_id and type timelines';

}

# runes
{
  my $runes;
  $runes = $lol->runes( summoner_id => 1 );
  is $runes, 'https://na1.api.riotgames.com/lol/platform/v3/runes/by-summoner/1?api_key=testing', 'runes w/ summoner_id';
}

# spectator
{
  my $spectator;
  $spectator = $lol->spectator( summoner_id => 1 );
  is $spectator, 'https://na1.api.riotgames.com/lol/spectator/v3/active-games/by-summoner/1?api_key=testing', 'spectator w/ summoner_id';

  $spectator = $lol->spectator();
  is $spectator, 'https://na1.api.riotgames.com/lol/spectator/v3/featured-games?api_key=testing', 'spectator featured-games';
}

# summoner
{
  my $summoner;
  $summoner = $lol->summoner( account_id => 1 );
  is $summoner, 'https://na1.api.riotgames.com/lol/summoner/v3/summoners/by-account/1?api_key=testing', 'summoner w/ account_id';

  $summoner = $lol->summoner( summoner_name => 'foo' );
  is $summoner, 'https://na1.api.riotgames.com/lol/summoner/v3/summoners/by-name/foo?api_key=testing', 'summoner w/ summoner_name';

  $summoner = $lol->summoner( summoner_id => 1 );
  is $summoner, 'https://na1.api.riotgames.com/lol/summoner/v3/summoners/1?api_key=testing', 'summoner w/ summoner_id';
}

done_testing();
